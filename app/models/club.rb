class Club < ActiveRecord::Base
  has_many :hedgehogs
  
  def children
    Club.where('path && ARRAY[?]', self.id)
  end
  
  def parents
    Club.where('ARRAY[id] && ARRAY[?]', self.path)
  end
  
  def depth
    self.path.length
  end
end
