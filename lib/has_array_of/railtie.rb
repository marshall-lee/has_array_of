module HasArrayOf
  class Railtie < ::Rails::Railtie
    ActiveSupport.on_load(:active_record) do
      ActiveRecord::Base.send :include, HasArrayOf::Builders
    end
  end
end
