module HasArrayOf
  module Builders
    extend ActiveSupport::Concern

    module ClassMethods
      def has_array_of(name, **options)
        extension = if block_given?
          Module.new { yield }
        end
        class_name = (options[:class_name] || name.to_s.singularize.camelize).to_s

        AssociatedArray.new(
          self,
          name,
          class_name,
          extension
        )
      end

      def belongs_to_array_in_many(name, **options)
        name = name.to_s
        class_name = (options[:class_name] || name.singularize.camelize).to_s
        array_name = if options[:array_name]
                       options[:array_name].to_s
                     else
                       self.name.underscore.pluralize
                     end
        AssociatedBelongs.new(
          self,
          name,
          class_name,
          array_name
        )
      end
    end
  end
end
