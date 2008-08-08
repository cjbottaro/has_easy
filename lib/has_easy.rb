require 'has_easy/association_extension'
require 'has_easy/configurator'
require 'has_easy/definition'
require 'has_easy/errors'
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
        
        
        
        configurator = Configurator.new(self, context, options)
        yield configurator
        configurator.do_metaprogramming_magic_aka_define_methods
        has_easy_configurators[context] = configurator
      end
      
    end
    
    module InstanceMethods
      
      def set_has_easy_thing(context, name, value, do_preprocess = false)
        context = Helpers.normalize(context)
        name = Helpers.normalize(name)
        
        # TODO dry this shit out, it's a copy/paste job with get_has_easy_thing
        
        # check to make sure the context exists
        raise ArgumentError, "has_easy('#{context}') is not defined for class #{self.class}" \
          unless self.class.has_easy_configurators.has_key?(context)
        configurator = self.class.has_easy_configurators[context]
        
        # check to make sure the name of the thing exists
        raise ArgumentError, "'#{name}' not defined for has_easy('#{context}') for class #{self.class}" \
          unless configurator.definitions.has_key?(name)
        definition = configurator.definitions[name]
        
        # do preprocess here, type_check and validate can be done as AR validation in HasEasyThing
        value = definition.preprocess.call(value) if do_preprocess and definition.has_preprocess
        
        # invoke the assocation
        things = send(context)
        
        # if thing already exists, update it, otherwise add a new one
        thing = things.detect{ |thing| thing.name == name }
        if thing.blank?
          thing = HasEasyThing.new :context => context,
                                   :name => name,
                                   :value => value
          thing.set_model_target(self) # for the bug regarding thing's validation trying to invoke the 'model' assocation when self is a new record
          send("#{context}").send("<<", thing)
        else
          thing.value = value
        end
        
        thing.value
        
      end
      
      def get_has_easy_thing(context, name, do_postprocess = false)
        context = Helpers.normalize(context)
        name = Helpers.normalize(name)
        
        # check to make sure the context exists
        raise ArgumentError, "has_easy('#{context}') is not defined for class #{self.class}" \
          unless self.class.has_easy_configurators.has_key?(context)
        configurator = self.class.has_easy_configurators[context]
        
        # check to make sure the name of the thing exists
        raise ArgumentError, "'#{name}' not defined for has_easy('#{context}') for class #{self.class}" \
          unless configurator.definitions.has_key?(name)
        definition = configurator.definitions[name]
        
        # invoke the association
        things = send(context)
        
        # try to find what they are looking for
        thing = things.detect{ |thing| thing.name == name }
        
        # if the thing isn't found, try to fallback on a default
        if thing.blank?
          # TODO break all these nested if statements out into helper methods, i like prettier code
          # TODO raise an exception if we don't respond to default_through or the resulting object doesn't respond to the context
          if definition.has_default_through and respond_to?(definition.default_through) and (through = send(definition.default_through)).blank? == false
            value = through.send(context)[name]
          elsif definition.has_default_dynamic
            if definition.default_dynamic.instance_of?(Proc)
              value = definition.default_dynamic.call(self)
            else
              # TODO raise an exception if we don't respond to default_dynamic
              value = send(definition.default_dynamic)
            end
          elsif definition.has_default
            value = Marshal::load(Marshal.dump(definition.default)) # BUGFIX deep cloning default values
          else
            value = nil
          end
        else
          value = thing.value
        end
        
        value = definition.postprocess.call(value) if do_postprocess and definition.has_postprocess
        value
      end
      
    end
    
  end
  
end
