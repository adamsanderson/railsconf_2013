require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test "you can search for stemmed words" do
    found = Comment.search_all("enjoying")
    
    assert found.include?(comments(:eyes))
    assert found.include?(comments(:beets))
    assert found.include?(comments(:oranges))
    assert found.include?(comments(:grapes))
  end
  
  test "you can search with wildcards and multiple terms" do
    found = Comment.search_all("quil* oil")
    
    assert found == [comments(:oil)]
  end
  
  test "you can eager load related models when searching" do
    found = Comment.search_all("quil* oil").includes(:hedgehog)
    
    assert_equal hedgehogs(:bartleby), found.first.hedgehog
  end
  
  test "sanitizes user prefix wildcards" do
    found = Comment.search_any("*:quil oil")
    assert found.length > 0
  end
  
  test "sanitizes apostrophes" do
    assert_nothing_raised do
      Comment.search_any("quil'oil")
    end
  end
  
  test "sanitizes colons" do
    assert_nothing_raised do
      Comment.search_any(":quil")
      Comment.search_any("quil:")
      Comment.search_any("qu:il")
    end
  end
  
end
