class HasArrayOf::AssociatedBelongs
  def initialize(model, name, class_name, array_name)
    @class_name = class_name

    setup = self

    with_method_name = "with_#{array_name}_containing"
    model.class_eval do
      define_method name do
        setup.associated_model.send(with_method_name, [self])
      end
    end
  end

  def associated_model
    @associated_model ||= @class_name.constantize
  end
end
