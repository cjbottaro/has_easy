require File.dirname(__FILE__) + '/../../../../test/test_helper'

ActiveRecord::Base.connection.create_table :has_easy_user_tests, :force => true do
end

class HasEasyUserTest < ActiveRecord::Base
  has_easy :preferences do |p|
    p.define :color
  end
  has_easy :flags do |f|
    f.define :admin
  end
end

class HasEasyTest < Test::Unit::TestCase
  
  def setup
    @user = HasEasyUserTest.create
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
  
end
