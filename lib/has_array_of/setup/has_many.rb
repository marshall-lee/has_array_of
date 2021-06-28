class HasArrayOf::Setup::HasMany
  attr_reader :ids_attribute

  def initialize(owner_model, name, class_name, extension)
    singular_name = name.to_s.singularize
    @class_name = class_name
    @ids_attribute = ids_attribute = "#{singular_name}_ids".to_sym
    @primary_key = primary_key = owner_model.primary_key
    @name = name

    setup = self

    owner_model.class_eval do
      define_method name do
        # TODO: invoke a subclass of CollectionProxy
        HasArrayOf::CollectionProxy.new(setup, self)
      end

      define_method "#{name}=" do |objects|
        ids = if objects.respond_to? :pluck
                objects.pluck(primary_key)
              else
                objects.map { |obj| setup.try_pkey(obj) }
              end
        write_attribute(ids_attribute, ids)
      end

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

  def try_pkey(obj)
    obj[@primary_key] if obj
  end

  def coerce_ids(first_obj, *rest_objs)
    ary = if rest_objs.empty?
      Array.wrap(first_obj)
    else
      [first_obj, *rest_objs]
    end
    ary.map { |obj| try_pkey(obj) }
  end

  def model
    # Model must be loaded lazily
    @model ||= @class_name.constantize
  end

  def foreign_key
    @foreign_key ||= model.primary_key
  end
end
