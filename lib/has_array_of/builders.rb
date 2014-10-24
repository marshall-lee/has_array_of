require 'has_array_of/associated_array'
require 'has_array_of/associated_belongs'

module HasArrayOf
  module Builders
    extend ActiveSupport::Concern

    module ClassMethods
      def has_array_of(name, options = {})
        extension = if block_given?
          Module.new(&proc)
        end
        singular_name = name.to_s.singularize
        class_name = (options[:class_name] || singular_name.camelize).to_s
        ids_attribute = "#{singular_name}_ids".to_sym
        model = class_name.constantize
        pkey_attribute = model.primary_key.to_sym

        AssociatedArray.define_in self, name: name,
                                        singular_name: singular_name,
                                        ids_attribute: ids_attribute,
                                        model: model,
                                        pkey_attribute: pkey_attribute,
                                        extension: extension
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
        AssociatedBelongs.define_in self, singular_name: singular_name,
                                          name: name,
                                          class_name: class_name,
                                          array_name: array_name
      end
    end
  end
end
