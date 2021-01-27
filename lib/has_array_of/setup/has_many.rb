class HasArrayOf::Setup::HasMany
  def initialize(owner_model, name, class_name, extension)
    singular_name = name.to_s.singularize
    ids_attribute = "#{singular_name}_ids".to_sym
    @owner_model = owner_model
    @name = name
    @class_name = class_name

    setup = self

    owner_model.class_eval do
      define_method name do
        HasArrayOf::CollectionProxy.new(self, setup.model, ids_attribute)
      end

      define_method "#{name}=" do |objects|
        ids = if objects.respond_to? :pluck
                objects.pluck(owner_model.primary_key)
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
    obj.try(@owner_model.primary_key)
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
    @model ||= @class_name.constantize
  end
end
