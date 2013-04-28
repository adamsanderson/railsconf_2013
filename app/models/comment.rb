class Comment < ActiveRecord::Base
  belongs_to :hedgehog
  
  scope :search_all, -> (query){ 
    where("to_tsvector('english', comment) @@ #{sanitize_query(query, ' && ')}")
  }
  
  scope :search_any, -> (query){ 
    where("to_tsvector('english', comment) @@ #{sanitize_query(query, ' || ')}")
  }
  
  private
  
  # Sanitizes a query returning a set of valid tsqueries joined by the 
  # conjunction.
  def self.sanitize_query(query, conjunction=' && ')
    "(" + tokenize_query(query).map{|t| term(t)}.join(conjunction) + ")"
  end
  
  # Breaks a query into search terms.
  def self.tokenize_query(query)
    query.split(/(\s|[&|:])+/)
  end
  
  # This will sanitize each search term.
  # 
  # There are more succinct ways to do this, but the following will remove each 
  # invalid case.
  def self.term(t)
    # Strip leading apostrophes, they are never legal, "'ok" becomes "ok"
    t = t.gsub(/^'+/,'')
    # Strip any *s that are not at the end of the term
    t = t.gsub(/\*[^$]/,'')
    # Rewrite "sear*" as "sear:*" to support wildcard matching on terms
    t = t.gsub(/\*$/,':*')
    # If the only remaining text is a wildcard, return an empty string
    t = "" if t.match(/^[:* ]+$/)
    
    "to_tsquery('english', #{quote_value t})"
  end
end
