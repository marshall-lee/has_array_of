module HasArrayOf
  module Association
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_array_of(name, scope = nil, options = {}, &extension)
        if scope.is_a?(Hash)
          options = scope
          scope = nil
        end
        if block_given?
          mod = Module.new(&Proc.new)
          if scope
            proc { |owner| instance_exec(owner, &scope).extending(mod) }
          else
            proc { extending(mod) }
          end
        end
        singular_name = name.to_s.singularize
        class_name = (options[:class_name] || singular_name.camelize).to_s
        ids_method_name = "#{singular_name}_ids".to_sym
        model = class_name.constantize
        primary_key = model.primary_key.to_sym
        primary_key_proc = primary_key.to_proc
        mutate_method_name = "_mutate_#{ids_method_name}".to_sym

        define_method name do
          ids = send(ids_method_name)
          owner = self
          query = model.arel_table[primary_key].in(ids)
          model.where(query).extending do
            define_method mutate_method_name do |&block|
              reset
              where_values.reject! { |v| v == query }
              ret = block.call
              owner.send(:write_attribute, ids_method_name, ids)
              query = model.arel_table[primary_key].in(ids)
              where! query
              ret
            end
            define_method :<< do |object|
              send(mutate_method_name) do
                ids << object.send(primary_key)
                self
              end
            end
            define_method :[]= do |*index, val|
              send(mutate_method_name) do
                if val.is_a? Array
                  ids[*index] = val.map(&primary_key_proc)
                else
                  ids[*index] = val.send(primary_key)
                end
                val
              end
            end

            define_method :to_a do
              hash = super().reduce({}) do |memo, object|
                memo[object.send(primary_key)] = object
                memo
              end
              ids.map { |id| hash[id] }.compact
            end
          end
        end

        define_method "#{name}=" do |objects|
          ids = if objects.respond_to? :pluck
                  objects.pluck(model.primary_key)
                else
                  objects.map { |obj| obj.send model.primary_key }
                end
          write_attribute(ids_method_name, ids)
        end

        define_singleton_method "with_#{name}_containing" do |arg, *args|
          ary = if args.any?
                  [arg, *args]
                elsif arg.is_a? Array
                  arg
                end
          if ary
            where "#{ids_method_name} @> ARRAY[#{ary.map(&primary_key_proc).join(',')}]"
          else
            where "#{ids_method_name} @> ARRAY(#{arg.select(primary_key).to_sql})"
          end
        end

        define_singleton_method "with_#{name}_contained_in" do |arg, *args|
          ary = if args.any?
                  [arg, *args]
                elsif arg.is_a? Array
                  arg
                end
          if ary
            where "#{ids_method_name} <@ ARRAY[#{ary.map(&primary_key_proc).join(',')}]"
          else
            where "#{ids_method_name} <@ ARRAY(#{arg.select(primary_key).to_sql})"
          end
        end

        define_singleton_method "with_any_#{singular_name}_from" do |arg, *args|
          ary = if args.any?
                  [arg, *args]
                elsif arg.is_a? Array
                  arg
                end
          if ary
            where "#{ids_method_name} && ARRAY[#{ary.map(&primary_key_proc).join(',')}]"
          else
            where "#{ids_method_name} && ARRAY(#{arg.select(primary_key).to_sql})"
          end
        end
      end

      def belongs_to_array_in_many(singular_name, options={})
        singular_name = singular_name.to_s
        name = singular_name.pluralize
        class_name = (options[:class_name] || singular_name.camelize).to_s
        array_name = if options[:array_name]
                       options[:array_name].to_s
                     else
                       self.name.underscore.pluralize
                     end
        with_method_name = "with_#{array_name}_containing"
        model_method_name = "_#{name}_model"

        define_singleton_method model_method_name do
          instance_variable_get("@_#{model_method_name}") or
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
