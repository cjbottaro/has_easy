require File.dirname(__FILE__) + '/../../../../test/test_helper'

ActiveRecord::Base.connection.create_table :has_easy_user_tests, :force => true do |t|
  t.integer :client_id
end

ActiveRecord::Base.connection.create_table :has_easy_client_tests, :force => true do
end

HasEasyThing.delete_all

class HasEasyClientTest < ActiveRecord::Base
  has_many :users, :class_name => 'HasEasyUserTest', :foreign_key => 'client_id'
  has_easy :flags do |f|
    f.define :default_through_test_1, :default => 'client default'
  end
end

class HasEasyUserTest < ActiveRecord::Base
  belongs_to :client, :class_name => 'HasEasyClientTest', :foreign_key => 'client_id'
  cattr_accessor :count1, :count2
  @@count1, @@count2 = 0, 0
  has_easy :preferences, :alias => :prefs do |p|
    p.define :color
    p.define :theme, :type_check => String
    p.define :validate_test_1, :validate => [true, 'true', 1, 't']
    p.define :validate_test_2, :validate => Proc.new { |value|
      [true, 'true', 1, 't'].include?(value)
    }
    p.define :validate_test_3, :validate => Proc.new { |value|
      raise HasEasy::ValidationError unless [true, 'true', 1, 't'].include?(value)
    }
    p.define :validate_test_4, :validate => :validate_test_4
    p.define :preprocess_test_1, :preprocess => Proc.new { |value| [true, 'true', 1, 't'].include?(value) ? true : false }
    p.define :postprocess_test_1, :postprocess => Proc.new { |value| [true, 'true', 1, 't'].include?(value) ? true : false }
    p.define :form_usage_test, :default => false,
                               :type_check => [TrueClass, FalseClass],
                               :preprocess => Proc.new{ |value| value == 'true' },
                               :postprocess => Proc.new{ |value| value ? 'true' : 'false' }
  end
  has_easy :flags do |f|
    f.define :admin
    f.define :default_test_1, :default => 'funky town'
    f.define :default_through_test_1, :default => 'user default', :default_through => :client
    f.define :default_dynamic_test_1, :default_dynamic => :default_dynamic_test_1
    f.define :default_dynamic_test_2, :default_dynamic => Proc.new{ |user| user.class.count2 += 1 }
    f.define :default_reference, :default => [1, 2, 3] # demonstrates a bug found by swaltered
  end
  
  def validate_test_4(value)
    ["1one", "2two"]
  end
  
  def default_dynamic_test_1
    self.class.count1 += 1
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
  
  def test_alias
    @user.preferences.theme = "savage thunder"
    assert_equal @user.preferences[:theme], @user.prefs[:theme]
    assert_equal @user.preferences.theme, @user.prefs.theme
    assert_equal @user.preferences_theme, @user.prefs_theme
    assert_equal @user.preferences_theme?, @user.prefs_theme?
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
  
  def test_validate_4
    @user.preferences.validate_test_4 = "blah"
    assert_raise(ActiveRecord::RecordInvalid){ @user.preferences.save! }
    assert !@user.preferences.save
    assert 2, @user.errors.on(:preferences).length
    assert '1one', @user.errors.on(:preferences)[0]
    assert '2two', @user.errors.on(:preferences)[1]
    
    # nasty bug when the parent is a new record
    user = @user.class.new :preferences_validate_test_4 => "blah"
    assert !user.save
    assert 2, @user.errors.on(:preferences).length
    assert '1one', @user.errors.on(:preferences)[0]
    assert '2two', @user.errors.on(:preferences)[1]
  end
  
  def test_validate_4_has_easy_errors_added_to_base
    @user.preferences.validate_test_4 = "blah"
    @user.preferences.save
    @preference = @user.preferences.detect { |pref|  !pref.errors.empty? }
    assert_equal ['1one','2two'], @preference.errors.full_messages 
  end
  
  def test_preprocess_1
    @user.preferences.preprocess_test_1 = "blah"
    assert_equal "blah", @user.preferences.preprocess_test_1
    assert_equal "blah", @user.preferences_preprocess_test_1
    @user.preferences_preprocess_test_1 = "blah"
    assert_equal false, @user.preferences.preprocess_test_1
    assert_equal false, @user.preferences_preprocess_test_1
    
    @user.preferences.preprocess_test_1 = "true"
    assert_equal "true", @user.preferences.preprocess_test_1
    assert_equal "true", @user.preferences_preprocess_test_1
    @user.preferences_preprocess_test_1 = "true"
    assert_equal true, @user.preferences.preprocess_test_1
    assert_equal true, @user.preferences_preprocess_test_1
  end
  
  def test_postprocess_1
    @user.preferences.postprocess_test_1 = "blah"
    assert_equal "blah", @user.preferences.postprocess_test_1
    assert_equal false, @user.preferences_postprocess_test_1
    
    @user.preferences.postprocess_test_1 = "true"
    assert_equal "true", @user.preferences.postprocess_test_1
    assert_equal true, @user.preferences_postprocess_test_1
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
  
  def test_default_dynamic_1
    assert_equal 1, @user.flags.default_dynamic_test_1
    assert_equal 2, @user.flags.default_dynamic_test_1
  end
  
  def test_default_dynamic_2
    assert_equal 1, @user.flags.default_dynamic_test_2
    assert_equal 2, @user.flags.default_dynamic_test_2
  end
  
  # This is from a bug that swalterd found that has to do with how has_easy assigns default values.
  # Each thing shares the same default value, so changing it for one will change it for everyone.
  # The fix is to clone (if possible) the default value when a new HasEasyThing is created.
  def test_default_reference
    v = @user.flags.default_reference[0]
    @user.flags.default_reference[0] = rand(10) + 10
    new_user = HasEasyUserTest.new
    assert_equal v, new_user.flags_default_reference[0]
  end
  
  def test_form_usage
    assert_equal false, @user.prefs.form_usage_test
    assert_equal 'false', @user.prefs_form_usage_test
    
    params = { :person => {:prefs_form_usage_test => 'true'} }
    assert @user.update_attributes(params[:person])
    assert_equal true, @user.prefs.form_usage_test
    assert_equal 'true', @user.prefs_form_usage_test
    @user.preferences.save!
    @user = @user.class.find(@user.id)
    assert_equal true, @user.prefs.form_usage_test
    assert_equal 'true', @user.prefs_form_usage_test
    
    params = { :person => {:prefs_form_usage_test => 'false'} }
    assert @user.update_attributes(params[:person])
    assert_equal false, @user.prefs.form_usage_test
    assert_equal 'false', @user.prefs_form_usage_test
    @user.preferences.save!
    @user = @user.class.find(@user.id)
    assert_equal false, @user.prefs.form_usage_test
    assert_equal 'false', @user.prefs_form_usage_test
  end
  
end
