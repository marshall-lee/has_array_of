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
        ids_name = "#{singular_name}_ids".to_sym
        model = class_name.constantize
        primary_key = model.primary_key
        primary_key_proc = primary_key.to_sym.to_proc

        define_method name do
          ids = send(ids_name)
          owner = self
          query = model.arel_table[primary_key].in(ids)
          model.where(query).extending do
            define_method :<< do |*objects|
              reset
              where_values.reject! { |v| v == query }
              ids.concat(objects.map(&primary_key_proc))
              owner.send(:write_attribute, ids_name, ids)
              query = model.arel_table[primary_key].in(ids)
              where! query
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
          write_attribute(ids_name, ids)
        end

        define_singleton_method "including_#{name}" do |arg, *args|
          ary = if args.any?
                  [arg, *args]
                elsif arg.is_a? Array
                  arg
                end
          if ary
            where "#{ids_name} @> ARRAY[#{ary.map(&primary_key_proc).join(',')}]"
          else
            where "#{ids_name} @> ARRAY(#{arg.select(primary_key).to_sql})"
          end
        end

        define_singleton_method "including_any_of_#{name}" do |arg, *args|
          ary = if args.any?
                  [arg, *args]
                elsif arg.is_a? Array
                  arg
                end
          if ary
            where "#{ids_name} && ARRAY[#{ary.map(&primary_key_proc).join(',')}]"
          else
            where "#{ids_name} && ARRAY(#{arg.select(primary_key).to_sql})"
          end
        end
      end

      def contained_in_array_from(singular_name, options={})
        singular_name = singular_name.to_s
        name = singular_name.pluralize
        class_name = (options[:class_name] || singular_name.camelize).to_s
        array_name = if options[:array_name]
                       options[:array_name].to_s
                     else
                       self.name.underscore.pluralize
                     end
        including_name = "including_#{array_name}"
        including_any_of_name = "including_any_of_#{array_name}"

        define_method name do
          model = class_name.constantize
          model.send(including_name, [self])
        end

        define_singleton_method "all_#{name}" do
          model = class_name.constantize
          model.send(including_any_of_name, self)
        end

        define_singleton_method "#{name}_contained_by" do
          model = class_name.constantize
          model.send(including_name, self)
        end
      end
    end
  end
end
