require File.dirname(__FILE__) + '/../../../../test/test_helper'

ActiveRecord::Base.connection.create_table :has_easy_user_tests, :force => true do |t|
  t.integer :client_id
end

ActiveRecord::Base.connection.create_table :has_easy_client_tests, :force => true do
end

class HasEasyClientTest < ActiveRecord::Base
  has_many :users, :class_name => 'HasEasyUserTest', :foreign_key => 'client_id'
  has_easy :flags do |f|
    f.define :default_through_test_1, :default => 'client default'
  end
end

class HasEasyUserTest < ActiveRecord::Base
  belongs_to :client, :class_name => 'HasEasyClientTest', :foreign_key => 'client_id'
  
  has_easy :preferences do |p|
    p.define :color
    p.define :theme, :type_check => String
    p.define :validate_test_1, :validate => [true, 'true', 1, 't']
    p.define :validate_test_2, :validate => Proc.new { |value|
      [true, 'true', 1, 't'].include?(value)
    }
    p.define :validate_test_3, :validate => Proc.new { |value|
      raise HasEasy::ValidationError unless [true, 'true', 1, 't'].include?(value)
    }
    p.define :preprocess_test_1, :preprocess => Proc.new { |value| [true, 'true', 1, 't'].include?(value) ? true : false }
  end
  has_easy :flags do |f|
    f.define :admin
    f.define :default_test_1, :default => 'funky town'
    f.define :default_through_test_1, :default => 'user default', :default_through => :client
  end
end

class HasEasyTest < Test::Unit::TestCase
  
  def setup
    @client = HasEasyClientTest.create
    @user = @client.users.create!
  end
  
  def test_setter_getter
    @user.set_has_easy_thing(:preferences, :color, 'red')
    assert_equal 'red', @user.get_has_easy_thing(:preferences, :color)
    assert_equal 1, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
    
    @user.set_has_easy_thing(:flags, :admin, true)
    assert_equal true, @user.get_has_easy_thing(:flags, :admin)
    assert_equal 2, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
  end
  
  def test_array_access
    @user.preferences[:color] = 'red'
    assert_equal 'red', @user.preferences[:color]
    assert_equal 1, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
    
    @user.flags[:admin] = true
    assert_equal true, @user.flags[:admin]
    assert_equal 2, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
  end
  
  def test_object_access
    @user.preferences.color = 'red'
    assert_equal 'red', @user.preferences.color
    assert_equal 1, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
    
    @user.flags.admin = true
    assert_equal true, @user.flags.admin
    assert_equal 2, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
  end
  
  def test_easy_access
    @user.preferences_color = 'red'
    assert_equal 'red', @user.preferences_color
    assert_equal true, @user.preferences_color?
    assert_equal 1, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
    
    @user.flags_admin = true
    assert_equal true, @user.flags_admin
    assert_equal true, @user.flags_admin?
    assert_equal 2, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
  end
  
  def test_overwrite
    @user.preferences[:color] = 'red'
    assert_equal 'red', @user.preferences[:color]
    assert_equal 1, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
    
    @user.preferences[:color] = 'blue'
    assert_equal 'blue', @user.preferences[:color]
    assert_equal 1, HasEasyThing.count(:conditions => { :model_type => @user.class.name, :model_id => @user.id })
  end
  
  def test_type_check
    @user.preferences.theme = "savage thunder"
    assert @user.preferences.save
    
    @user.preferences.theme = 1
    assert_raise(ActiveRecord::RecordInvalid){ @user.preferences.save! }
    
    assert !@user.preferences.save
    assert !@user.errors.empty?
  end
  
  def test_validate_1
    @user.preferences.validate_test_1 = 1
    assert @user.preferences.save
    @user.preferences.validate_test_1 = true
    assert @user.preferences.save
    @user.preferences.validate_test_1 = 'true'
    assert @user.preferences.save
    
    @user.preferences.validate_test_1 = false
    assert_raise(ActiveRecord::RecordInvalid){ @user.preferences.save! }
    assert !@user.preferences.save
    assert !@user.errors.empty?
  end
  
  def test_validate_2
    @user.preferences.validate_test_2 = 1
    assert @user.preferences.save
    @user.preferences.validate_test_2 = true
    assert @user.preferences.save
    @user.preferences.validate_test_2 = 'true'
    assert @user.preferences.save
    
    @user.preferences.validate_test_2 = false
    assert_raise(ActiveRecord::RecordInvalid){ @user.preferences.save! }
    assert !@user.preferences.save
    assert !@user.errors.empty?
  end
  
  def test_validate_3
    @user.preferences.validate_test_3 = 1
    assert @user.preferences.save
    @user.preferences.validate_test_3 = true
    assert @user.preferences.save
    @user.preferences.validate_test_3 = 'true'
    assert @user.preferences.save
    
    @user.preferences.validate_test_3 = false
    assert_raise(ActiveRecord::RecordInvalid){ @user.preferences.save! }
    assert !@user.preferences.save
    assert !@user.errors.empty?
  end
  
  def test_preprocess_1
    @user.preferences.preprocess_test_1 = "blah"
    assert_equal false, @user.preferences.preprocess_test_1
    
    @user.preferences.preprocess_test_1 = "true"
    assert_equal true, @user.preferences.preprocess_test_1
  end
  
  def test_default_1
    assert_equal 'funky town', HasEasyUserTest.new.flags.default_test_1
    assert_equal 'funky town', @user.flags.default_test_1
    @user.flags.default_test_1 = "stupid town"
    assert_equal "stupid town", @user.flags.default_test_1
    @user.flags.save
    @user = HasEasyUserTest.find(@user.id)
    assert_equal "stupid town", @user.flags.default_test_1
  end
  
  def test_default_though_1
    client = HasEasyClientTest.create
    user = client.users.create
    assert_equal 'client default', user.flags.default_through_test_1
    
    client.flags.default_through_test_1 = 'not client default'
    client.flags.save
    user.client(true)
    assert_equal 'not client default', user.flags.default_through_test_1
    
    user.flags.default_through_test_1 = 'not user default'
    assert_equal 'not user default', user.flags.default_through_test_1
    
    assert_equal 'user default', HasEasyUserTest.new.flags.default_through_test_1
  end
  
end
