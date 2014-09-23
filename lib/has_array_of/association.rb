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
        define_method name do
          model.where(model.arel_table[model.primary_key].in(send(ids_name)))
        end
      end
    end
  end
end
