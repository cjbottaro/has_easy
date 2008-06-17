require 'has_easy/association_extension'
require 'has_easy/configurator'
require 'has_easy/definition'
require 'has_easy/helpers'
require 'has_easy_thing'

module Izzle
  
  module HasEasy
    
    def self.included(klass)
      klass.extend ClassMethods
      klass.send(:include, InstanceMethods)
    end
    
    module ClassMethods
      
      def has_easy(context = nil, options = {})
        context = Helpers.normalize(context)
        
        # initialize the class instance var to hold our configuration info
        class << self
          attr_accessor :has_easy_configurators unless method_defined?(:has_easy_configurators)
        end
        self.has_easy_configurators = {} if self.has_easy_configurators.nil?
        
        # don't let the user redefine a context
        raise ArgumentError, "class #{self} already has_easy('#{context}')" if self.has_easy_configurators.has_key?(context)
        
        configurator = Configurator.new(self, context)
        yield configurator
        configurator.do_metaprogramming_magic_aka_define_methods
        has_easy_configurators[context] = configurator
      end
      
    end
    
    module InstanceMethods
      
      def set_has_easy_thing(context, name, value)
        context = Helpers.normalize(context)
        name = Helpers.normalize(name)
        
        # TODO dry this shit out, it's a copy/paste job with get_has_easy_thing
        
        # check to make sure the context exists
        raise ArgumentError, "has_easy('#{context}') is not defined for class #{self.class}" \
          unless self.class.has_easy_configurators.has_key?(context)
        
        # check to make sure the name of the thing exists
        raise ArgumentError, "'#{name}' not defined for has_easy('#{context}') for class #{self.class}" \
          unless self.class.has_easy_configurators[context].definitions.has_key?(name)
        
        # TODO type_check, validate and preprocess value
        
        # invoke the assocation
        things = send(context)
        
        # if thing already exists, update it, otherwise add a new one
        thing = things.detect{ |thing| thing.name == name }
        if thing.blank?
          thing = HasEasyThing.new :context => context,
                                   :name => name,
                                   :value => value
          send("#{context}").send("<<", thing)
        else
          thing.value = value
        end
        
        thing.value
        
      end
      
      def get_has_easy_thing(context, name)
        context = Helpers.normalize(context)
        name = Helpers.normalize(name)
        
        # check to make sure the context exists
        raise ArgumentError, "has_easy('#{context}') is not defined for class #{self.class}" \
          unless self.class.has_easy_configurators.has_key?(context)
        
        # check to make sure the name of the thing exists
        raise ArgumentError, "'#{name}' not defined for has_easy('#{context}') for class #{self.class}" \
          unless self.class.has_easy_configurators[context].definitions.has_key?(name)
        
        # invoke the association
        things = send(context)
        
        # try to find what they are looking for
        thing = things.detect{ |thing| thing.name == name }
        
        # TODO return the default if the thing isn't found, but has a default
        return nil if thing.blank?
        
        thing.value
      end
      
    end
    
  end
  
end