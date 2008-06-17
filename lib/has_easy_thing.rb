class HasEasyThing < ActiveRecord::Base
  belongs_to :model, :polymorphic => true
  attr_accessor :model_cache, :definition, :value_cache
  before_validation :get_definition
  validate :validate_type_check, :validate_validate
  
  def get_definition
    self.model_cache = model if model_cache.blank?
    self.definition = model_cache.class.has_easy_configurators[self.context].definitions[self.name] if self.definition.blank?
  end
  
  def validate_type_check
    return unless definition.has_type_check
    self.errors.add(:value, "has_easy type check failed for '#{self.name}'") unless definition.type_check.include?(value.class)
  end
  
  def validate_validate
    return unless definition.has_validate
    if definition.validate.instance_of?(Array) and definition.validate.include?(value) == false
      self.errors.add(:value, "has_easy validation failed for '#{self.name}'")
    elsif definition.validate.instance_of?(Proc)
      begin
        failed = definition.validate.call(value) == false
      rescue HasEasy::ValidationError
        failed = true
      end
      self.errors.add(:value, "has_easy validation failed for '#{self.name}'") if failed
    end
  end
  
  def value=(v)
    method_missing(:value=, v.to_yaml)
    self.value_cache = v
  end
  
  def value
    self.value_cache ||= YAML.load(method_missing(:value))
  end
  
end