require 'test_helper'

class HedgehogTest < ActiveSupport::TestCase
  test "you can find hedgehogs by their tags" do
    hogs = Hedgehog.where "tags @> ARRAY[?]", ['spiny', 'prickly']
    
    assert !hogs.empty?
    assert hogs.all? do |hog| 
      hog.tags.include? 'spiny'
      hog.tags.include? 'prickly'
    end
  end
  
  test "you can find all the hedgehogs that are spiny or prickly, but not grumpy" do
    hogs = Hedgehog.where "tags && ARRAY[?]", ['spiny', 'prickly']
    hogs = hogs.where.not "tags && ARRAY[?]", ['grumpy']
    
    assert !hogs.empty?
    assert hogs.all? do |hog| 
      spiny   = hog.tags.include?('spiny')
      prickly = hog.tags.include?('prickly')
      grumpy  = hog.tags.include?('grumpy')
      (spiny || prickly) && !grumpy
    end
  end
  
  test "you can mix operations on arrays and normal conditions" do
    hogs = Hedgehog.where "tags && ARRAY[?]", ['spiny', 'large']
    hogs = hogs.where     "age > ?", 4
    
    assert !hogs.empty?
    assert hogs.all? do |hog| 
      spiny = hog.tags.include?('spiny')
      large = hog.tags.include?('large')
      old   = hog.age > 4
      
      (spiny || large) && old
    end
  end
  
  test "you can define scopes for querying tags" do
    hogs = Hedgehog.any_tags('spiny', 'large').where('age > ?', 4)
    
    assert !hogs.empty?
    assert hogs.all? do |hog| 
      spiny = hog.tags.include?('spiny')
      large = hog.tags.include?('large')
      old   = hog.age > 4
      
      (spiny || large) && old
    end
  end
  
  test "you can set custom objects on an hstore field" do
    hog = hedgehogs(:horrace)
    hog.custom = {"favorite_color" => "ochre", "weight" => "2lbs"}
    hog.save!
    
    hog.reload
    assert_equal "ochre", hog.custom["favorite_color"]
  end
  
  test "you can find all the records that define a given key" do
    hogs = Hedgehog.has_key('color')
    assert !hogs.empty?
    assert hogs.all?{|h| h.custom.has_key? 'color' }
  end
  
  test "you can find all the records that define a given key and value" do
    expected = [hedgehogs(:bartleby), hedgehogs(:minzy), hedgehogs(:marty)].sort_by(&:id)
    hogs = Hedgehog.has_value('color', 'brown').sort_by(&:id)
    
    assert_equal hogs, expected
  end
  
  test "always returns strings" do
    hog = hedgehogs(:horrace)
    hog.custom = {"favorite_color" => :ochre, "weight" => 2}
    hog.save!
    
    hog.reload
    assert_equal "ochre", hog.custom["favorite_color"]
    assert_equal "2", hog.custom["weight"]
  end
end
