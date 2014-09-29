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
      end
    end
  end
end
