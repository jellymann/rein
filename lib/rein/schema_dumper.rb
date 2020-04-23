module Rein
  # @api private
  module SchemaDumper
    def tables(stream)
      super
      check_constraints(stream)
    end

    def check_constraints(stream)
      puts constraints.to_a

      stream.puts if constraints.any?

      constraints.each do |constraint|
        column_name = constraint['column_name']
        check_clause = constraint['check_clause']

        case check_clause
        when /#{column_name}\s+(>=|>|=|!=|<|<=)\s+(\d+)/
          add_numericality_constraint_command(stream, constraint, $1, $2)
        end
      end
    end

    private

    def constraints
      @constraints ||= @connection.execute <<-SQL
        select *
        from information_schema.check_constraints as c, information_schema.constraint_column_usage as u
        where c.constraint_name = u.constraint_name
          and c.constraint_schema = 'public'
          and u.constraint_schema = 'public'
      SQL
    end

    def add_numericality_constraint_command(stream, constraint, operator, value)
      table_name = constraint['table_name']
      column_name = constraint['column_name']

      definition = definition_from_numerical_operator(operator)
      stream.puts <<-RUBY
  add_numericality_constraint "#{table_name}", "#{column_name}", #{definition}: #{value}
      RUBY
    end

    def definition_from_numerical_operator(operator)
      case operator
      when '>=' then 'greater_than_or_equal_to'
      when '>'  then 'greater_than'
      when '<=' then 'less_than_or_equal_to'
      when '<'  then 'less_than'
      when '='  then 'equal_to'
      when '!=' then 'not_equal_to'
      end
    end
  end
end
