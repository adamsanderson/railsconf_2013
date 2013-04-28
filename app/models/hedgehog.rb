class Hedgehog < ActiveRecord::Base
  belongs_to :club
  
  scope :any_tags, -> (* tags){where('tags && ARRAY[?]', tags)}
  scope :all_tags, -> (* tags){where('tags @> ARRAY[?]', tags)}
  
  scope :has_key,   -> (key){ where('defined(custom, ?)', key) }
  scope :has_value, -> (key, value){ where('custom -> ? = ?', key, value )}
  
end
