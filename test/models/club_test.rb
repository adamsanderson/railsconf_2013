require 'test_helper'

class ClubTest < ActiveSupport::TestCase
  test "you can find the children of a club" do
    club = clubs(:california)
    
    children = club.children
    assert !children.empty?
    
    children.each do |child|
      assert child.path.include?(club.id), "Expected #{child.path.inspect} to contain #{club.id}"
    end
  end
  
  test "you can find the parents of a club" do
    club = clubs(:portland)
    
    parents = club.parents
    assert !parents.empty?
    
    assert_equal club.path.sort, parents.map{|p| p.id}.sort
  end
  
  test "you can get the depth of a club" do
    club = clubs(:portland)
    
    assert_equal 4, club.depth
  end
  
  test "you can limit the number of parents returned" do
    club = clubs(:portland)
    parents = club.parents.limit(2)
    
    assert_equal 2, parents.length
  end
  
  test "you can include hedgehogs" do
    club = clubs(:california)
    hog = hedgehogs(:minzy)
    hog.club = club
    hog.save!
    
    children = club.children.includes(:hedgehogs)

    assert children.any?{|child| child.hedgehogs.include? hog }
  end
  
  test "you can chain scopes" do
    club = clubs(:california)
    hog = hedgehogs(:minzy)
    hog.club = club
    hog.save!
    
    children = club.children.joins(:hedgehogs).merge(Hedgehog.any_tags('silly'))
    
    assert_equal 1, children.length
    assert_equal [hog], children.first.hedgehogs
  end
  
  test "you can combine filtering clubs with all of our other features" do
    club = clubs(:california)
    hog = hedgehogs(:minzy)
    hog.club = club
    hog.custom = {color: 'brown'}
    hog.save!
    
    children = club.children.joins(:hedgehogs).merge(
      Hedgehog.any_tags('silly')
              .has_value('color', 'brown')
    )
        
    assert_equal 1, children.length
    assert_equal [hog], children.first.hedgehogs
  end
end

