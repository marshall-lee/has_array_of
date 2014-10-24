module HasArrayOf
  module AssociatedBelongs
    def define_in(model, options)
      name = options[:name]
      array_name = options[:array_name]
      class_name = options[:class_name]
      with_method_name = "with_#{array_name}_containing"
      model_method_name = "_#{name}_model"
      model.class_eval do
        define_singleton_method model_method_name do
          instance_variable_get("@_#{model_method_name}") ||
            instance_variable_set("@_#{model_method_name}", class_name.constantize)
        end

        define_method name do
          model = self.class.send(model_method_name)
          model.send(with_method_name, [self])
        end
      end
    end
  end
end
