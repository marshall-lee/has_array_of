class HasArrayOf::Setup::HasMany
  attr_reader :owner_model, :name, :ids_attribute

  def initialize(owner_model, name, class_name, extension)
    singular_name = name.to_s.singularize
    @class_name = class_name
    @ids_attribute = ids_attribute = "#{singular_name}_ids".to_sym
    @owner_model = owner_model
    @name = name

    setup = self

    owner_model.class_eval do
      define_singleton_method("__has_array_of_#{name}_setup__") { setup }
    end

    owner_model.class_eval <<~RUBY
      def #{name}
        @__has_array_of_#{name}__ ||= self.class.__has_array_of_#{name}_setup__.collection_proxy_class.new(self)
      end

      def #{name}=(objects)
        (@__has_array_of_#{name}__ ||= self.class.__has_array_of_#{name}_setup__.collection_proxy_class.new(self)).target = objects
      end
    RUBY

    owner_model.class_eval do
      define_singleton_method "with_#{name}_containing" do |*args|
        ids = setup.coerce_ids(*args)
        if ids.empty?
          all
        else
          where "#{ids_attribute} @> ARRAY[?]", ids
        end
      end

      define_singleton_method "with_#{name}_contained_in" do |*args|
        ids = setup.coerce_ids(*args)
        if ids.empty?
          none
        else
          where "#{ids_attribute} <@ ARRAY[?]", ids
        end
      end

      define_singleton_method "with_any_#{singular_name}_from" do |*args|
        ids = setup.coerce_ids(*args)
        if ids.empty?
          none
        else
          where "#{ids_attribute} && ARRAY[?]", ids
        end
      end
    end
  end

  def collection_proxy_class
    class_name = (@collection_proxy_class_name ||= :"HasArrayOf_#{@name.to_s.camelize}_CollectionProxy")
    return @owner_model.const_get(class_name, false) if @owner_model.const_defined?(class_name, false)

    @owner_model.const_set(
      class_name,
      ::HasArrayOf::CollectionProxy.subclass_for(self)
    )
  end

  def try_obj_key(obj)
    obj[model_pkey] if obj
  end

  def obj_key!(obj)
    raise_on_type_mismatch!(obj)
    obj[model_pkey]
  end

  def obj_key(obj)
    obj[model_pkey]
  end

  def coerce_ids(first_obj, *rest_objs)
    ary = if rest_objs.empty?
      Array.wrap(first_obj)
    else
      [first_obj, *rest_objs]
    end
    ary.map { |obj| try_obj_key(obj) }
  end

  def model
    # Model must be loaded lazily
    @model ||= @class_name.constantize
  end

  def model_pkey
    @model_pkey ||= model.primary_key
  end

  def raise_on_type_mismatch!(obj)
    unless obj.is_a?(model)
      raise ArgumentError, "#{owner_model.name}##{name} only accepts #{model.name} object"
    end
  end
end
