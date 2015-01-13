module HasArrayOf
  module AssociatedBelongs
    def self.define_in(model, options)
      name = options[:name]
      array_name = options[:array_name]
      class_name = options[:class_name]
      with_method_name = "with_#{array_name}_containing"
      model.class_eval do
        associated_model = nil
        associated_model_proc = -> { associated_model ||= class_name.constantize }

        define_method name do
          associated_model_proc.call.send(with_method_name, [self])
        end
      end
    end
  end
end
