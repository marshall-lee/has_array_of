module HasArrayOf::AssociatedArray
  def self.define_in(owner_model, options)
    name = options[:name]
    singular_name = options[:singular_name]
    ids_attribute = options[:ids_attribute]
    pkey_attribute = options[:pkey_attribute]
    try_pkey_proc = options[:try_pkey_proc] = proc { |obj| obj.try(pkey_attribute) }
    # pkey_attribute_sql_type = owner_model.columns_hash[pkey_attribute.to_s].sql_type
    owner_model.class_eval do
      define_method name do
        Relation.new(self, options[:model], ids_attribute, options)
      end

      define_method "#{name}=" do |objects|
        ids = if objects.blank?
                []
              elsif objects.respond_to? :pluck
                objects.pluck(pkey_attribute)
              elsif String === objects.first || Integer === objects.first
                objects.delete_if(&:blank?).map(&:to_i)
              else
                objects.map(&try_pkey_proc)
              end
        write_attribute(ids_attribute, ids)
      end

      expression = proc do |first, *rest|
        ary = if rest.empty?
                Array.wrap(first)
              else
                [first, *rest]
              end
        if ary.empty?
          "ARRAY[]::#{owner_model.columns_hash[ids_attribute.to_s].sql_type}[]"
        else
          "ARRAY[#{ary.map(&try_pkey_proc).join(',')}]"
        end
      end

      define_singleton_method "with_#{name}_containing" do |*args|
        where "#{ids_attribute} @> #{expression[args]}"
      end

      define_singleton_method "with_#{name}_contained_in" do |*args|
        where "#{ids_attribute} <@ #{expression[args]}"
      end

      define_singleton_method "with_any_#{singular_name}_from" do |*args|
        where "#{ids_attribute} && #{expression[args]}"
      end
    end
  end
end

require 'has_array_of/associated_array/relation.rb'
