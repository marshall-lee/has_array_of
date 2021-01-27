require 'active_record'

module HasArrayOf
  require 'has_array_of/associated_array'
  require 'has_array_of/associated_array/relation'
  require 'has_array_of/associated_belongs'
  require 'has_array_of/builders'
  require 'has_array_of/railtie' if defined?(Rails)
end
