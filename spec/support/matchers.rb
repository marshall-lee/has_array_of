require 'rspec/expectations'

RSpec::Matchers.define :have_sql_IN_stmt do |expected|
  if expected.empty?
    raise NotImplementedError
  elsif expected.one?
    match do |actual|
      actual.include? "= #{expected.first}"
    end
  elsif expected.many?
    match do |actual|
      actual.include? "IN (#{expected.join(', ')})"
    end
  end
end
