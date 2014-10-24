module HasArrayOf::AssociatedArray
  def self.define_in(owner_model, options)
    name = options[:name]
    singular_name = options[:singular_name]
    ids_attribute = options[:ids_attribute]
    pkey_attribute = options[:pkey_attribute]
    try_pkey_proc = options[:try_pkey_proc] = proc { |obj| obj.try(pkey_attribute) }
    owner_model.class_eval do
      define_method name do
        Relation.new(self, options)
      end

      define_method "#{name}=" do |objects|
        ids = if objects.respond_to? :pluck
                objects.pluck(pkey_attribute)
              else
                objects.map(&try_pkey_proc)
              end
        write_attribute(ids_attribute, ids)
      end

      define_singleton_method "with_#{name}_containing" do |arg, *args|
        ary = if args.any?
                [arg, *args]
              elsif arg.is_a? Array
                arg
              end
        if ary
          where "#{ids_attribute} @> ARRAY[#{ary.map(&try_pkey_proc).join(',')}]"
        else
          where "#{ids_attribute} @> ARRAY(#{arg.select(pkey_attribute).to_sql})"
        end
      end

      define_singleton_method "with_#{name}_contained_in" do |arg, *args|
        ary = if args.any?
                [arg, *args]
              elsif arg.is_a? Array
                arg
              end
        if ary
          where "#{ids_attribute} <@ ARRAY[#{ary.map(&try_pkey_proc).join(',')}]"
        else
          where "#{ids_attribute} <@ ARRAY(#{arg.select(pkey_attribute).to_sql})"
        end
      end

      define_singleton_method "with_any_#{singular_name}_from" do |arg, *args|
        ary = if args.any?
                [arg, *args]
              elsif arg.is_a? Array
                arg
              end
        if ary
          where "#{ids_attribute} && ARRAY[#{ary.map(&try_pkey_proc).join(',')}]"
        else
          where "#{ids_attribute} && ARRAY(#{arg.select(pkey_attribute).to_sql})"
        end
      end
    end
  end
end

require 'has_array_of/associated_array/relation.rb'
