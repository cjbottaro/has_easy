class HasEasyThing < ActiveRecord::Base
  belongs_to :model, :polymorphic => true
  attr_accessor :model_cache, :definition, :value_cache
  before_validation :get_definition
  validate :validate_type_check
  
  def get_definition
    self.model_cache = model if model_cache.blank?
    self.definition = model_cache.class.has_easy_configurators[self.context].definitions[self.name]
  end
  
  def validate_type_check
    #return unless definition.has_type_check
    #self.errors.add(:value, "type check failed for has_many('#{self.context}') #{self.name}")
  end
  
  def value=(v)
    method_missing(:value=, v.to_yaml)
    self.value_cache = v
  end
  
  def value
    self.value_cache ||= YAML.load(method_missing(:value))
  end
  
end