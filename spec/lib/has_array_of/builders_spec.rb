require 'spec_helper'

RSpec.describe HasArrayOf::Builders do
  describe ActiveRecord::Base do
    subject { described_class }
    it { should respond_to(:has_array_of) }
    it { should respond_to(:belongs_to_array_in_many) }
  end
end
