module Izzle
  module HasEasy
    class Definition
      
      attr_accessor :name
      attr_accessor :has_type_check,      :type_check
      attr_accessor :has_validate,        :validate
      attr_accessor :has_default,         :default
      attr_accessor :has_default_through, :default_through
      attr_accessor :has_default_dynamic, :default_dynamic
      attr_accessor :has_preprocess,      :preprocess
      attr_accessor :has_postprocess,     :postprocess
      
      def initialize(name, options = {})
        @name = name
        
        if options.has_key?(:type_check)
          @has_type_check = true
          @type_check = options[:type_check].instance_of?(Array) ? options[:type_check] : [options[:type_check]]
        end
        
        if options.has_key?(:validate)
          @has_validate = true
          @validate = options[:validate]
        end
        
        if options.has_key?(:default)
          @has_default = true
          @default = options[:default]
        end
        
        if options.has_key?(:default_through)
          @has_default_through = true
          @default_through = options[:default_through]
        end
        
        if options.has_key?(:default_dynamic)
          @has_default_dynamic = true
          @default_dynamic = options[:default_dynamic]
        end
        
        if options.has_key?(:preprocess)
          @has_preprocess = true
          @preprocess = options[:preprocess]
        end
        
        if options.has_key?(:postprocess)
          @has_postprocess = true
          @postprocess = options[:postprocess]
        end
        
      end
      
    end
  end
end
