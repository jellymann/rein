require 'spec_helper'

RSpec.describe Rein::SchemaDumper do
  it 'dumps constraints from the database' do
    stream = StringIO.new

    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)

    output = stream.string
    expect(output).to include 'add_numericality_constraint "books", "published_month", greater_than_or_equal_to: 1'
  end
end
