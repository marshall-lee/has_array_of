module HasArrayOf::AssociatedArray
  def self.define_in(owner_model, options)
    name = options[:name]
    singular_name = options[:singular_name]
    ids_attribute = options[:ids_attribute]
    try_pkey_proc = options[:try_pkey_proc] = proc { |obj| obj.try(owner_model.primary_key) }
    owner_model.class_eval do
      define_method name do
        Relation.new(self, options[:model], ids_attribute)
      end

      define_method "#{name}=" do |objects|
        ids = if objects.respond_to? :pluck
                objects.pluck(owner_model.primary_key)
              else
                objects.map(&try_pkey_proc)
              end
        write_attribute(ids_attribute, ids)
      end

      to_ids = proc do |first, *rest|
        ary = if rest.empty?
                Array.wrap(first)
              else
                [first, *rest]
              end
        ary.map(&try_pkey_proc)
      end

      define_singleton_method "with_#{name}_containing" do |*args|
        ids = to_ids[args]
        if ids.empty?
          all
        else
          where "#{ids_attribute} @> ARRAY[?]", ids
        end
      end

      define_singleton_method "with_#{name}_contained_in" do |*args|
        ids = to_ids[args]
        if ids.empty?
          none
        else
          where "#{ids_attribute} <@ ARRAY[?]", to_ids[args]
        end
      end

      define_singleton_method "with_any_#{singular_name}_from" do |*args|
        ids = to_ids[args]
        if ids.empty?
          none
        else
          where "#{ids_attribute} && ARRAY[?]", ids
        end
      end
    end
  end
end

require 'has_array_of/associated_array/relation.rb'
