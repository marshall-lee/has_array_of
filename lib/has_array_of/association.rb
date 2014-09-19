module HasArrayOf
  module Association
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def has_array_of
      end
    end
  end
end
