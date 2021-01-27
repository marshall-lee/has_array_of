require 'spec_helper'

RSpec.describe HasArrayOf::Macro do
  describe 'ApplicationRecord' do
    subject do
      Class.new(ActiveRecord::Base) do
        include HasArrayOf::Macro
      end
    end
    it { should respond_to(:has_array_of) }
    it { should respond_to(:belongs_to_array_in_many) }
  end
end
