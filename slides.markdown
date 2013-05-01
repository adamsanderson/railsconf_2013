Postgres, the Best Tool You're Already Using
--------------------------------------------

[Adam Sanderson](http://monkeyandcrow.com), [LiquidPlanner](http://liquidplanner.com)

---

Postgres
--------
The Best Tool You're Already Using
--------------------------------------------

* [Adam Sanderson](http://monkeyandcrow.com)
* [LiquidPlanner](http://liquidplanner.com)

<img src='images/lp_logo.png' style='width: 500px; position: absolute; left: 50px; bottom: 100px'/>
<img src='images/hedgehog_comment.png' style='width: 300px; position: absolute; right: 200px; bottom: 100px'/>

---

Adam Sanderson
--------------

I have been a full stack engineer at LiquidPlanner for 5 years.

* I got off in Kansas<sup>*</sup>, and that's ok!
* Github: [adamsanderson](https://github.com/adamsanderson)
* Twitter: [adamsanderson](https://twitter.com/adamsanderson)
* Blog: http://monkeyandcrow.com

<span class='footnote'>
  * Seattle
</span>

---

<img src='images/lp_logo.png' style='width: 500px; '/>

Online project management with probabilistic scheduling.

* Started in 2007 with Rails 1.x
* Used Postgres from the beginning
* We have learned some great techniques along the way

---

Topics
------

* Tagging
* Hierarchy
* Custom Data
* Full Text Search

---

Method
------

For each topic, we'll cover the SQL before we cover its use in ActiveRecord.

We will use Postgres 9.x, Ruby 1.9 syntax, and ActiveRecord 4.0.  

If you understand the SQL you can use it in any version of ActiveRecord, 4.0 just makes it easier.

---

Backstory
---------

You just built a great new social network for hedgehog lovers around the world, [HedgeWith.me](http://hedgewith.me/).  

Everything is going well. You have a few users, but now they want more.

<img src='images/hedgehog_mustache.png' style='width: 200px; position: absolute; left: 100px;'/>
<img src='images/hedgehog_comment.png' style='width: 280px; position: absolute; right: 300px;'/>

---

> My hedgehog is afraid of grumpy hedgehogs, but likes cute ones how can I find him friends?
<cite>hedgehogs4life</cite>

Tagging 
-------

People want to be able to tag their hedgehogs, and then find other hedgehogs with certain tags.

<img src='images/hedgehog_tags.png' style='width: 300px; position: absolute; left: 300px; bottom: 40px;'/>

---

Defining Arrays in SQL
----------------------

~~~ sql
CREATE TABLE hedgehogs (
    id      integer primary key,
    name    text,
    age     integer,
    tags    text[]
);
~~~

---

Defining Arrays in ActiveRecord
-------------------------------

~~~ ruby
create_table :hedgehogs do |t|
  t.string  :name
  t.integer :age
  t.text    :tags, array: true
end
~~~

ActiveRecord 4.x introduced arrays for Postgres, use `array:true`

---

Heads Up
--------

Define array columns as `t.text` instead of `t.string` to avoid casting.

Postgres assumes that `ARRAY['cute', 'cuddly']` is of type `text[]` and will require you to cast, otherwise you will see errors like this:

`ERROR:  operator does not exist: character varying[] && text[]`

---

Boolean Set Operators 
---------------------

You can use the set operators to query arrays.

* `A @> B` &nbsp; A contains all of B
* `A && B` &nbsp; A overlaps any of B


---

Querying Tags in SQL
------

Find all the hedgehogs that are <span class='highlight'>spiny</span> or <span class='highlight'>prickly</span>:

~~~ sql
SELECT name, tags FROM hedgehogs 
WHERE tags && ARRAY['spiny', 'prickly'];
~~~

<span class='footnote'>
`A && B` &nbsp; A overlaps any of B
</span>

---

Querying Tags in SQL 
------

   name   |            tags             
----------|-------------------------------
 Marty    | <span class='highlight'>spiny</span>, <span class='highlight'>prickly</span>, cute
 Quilby   | cuddly, <span class='highlight'>prickly</span>, hungry
 Thomas   | grumpy, <span class='highlight'>prickly</span>, sleepy, <span class='highlight'>spiny</span>
 Franklin | <span class='highlight'>spiny</span>, round, tiny


    
---

Querying Tags in SQL
------

Find all the hedgehogs that are <span class='highlight'>spiny</span> and <span class='highlight'>prickly</span>:

~~~ sql
SELECT name, tags FROM hedgehogs 
WHERE tags @> ARRAY['spiny', 'prickly'];
~~~

<span class='footnote'>
`A @> B` &nbsp; A contains all the B
</span>

---

Querying Tags in SQL 
------

  name  |            tags             
--------|-------------------------------
 Marty  | <span class='highlight'>spiny</span>, <span class='highlight'>prickly</span>, cute
 Thomas | grumpy, <span class='highlight'>prickly</span>, sleepy, <span class='highlight'>spiny</span>

    
---

Querying Tags in ActiveRecord
------------------------

Find all the hedgehogs that are spiny and prickly

~~~ ruby
Hedgehog.where "tags @> ARRAY[?]", ['spiny', 'prickly']
~~~

---

Querying Tags in ActiveRecord
------------------------

Create scopes to encapsulate set operations:

~~~ ruby
class Hedgehog < ActiveRecord::Base
  scope :any_tags, -> (* tags){where('tags && ARRAY[?]', tags)}
  scope :all_tags, -> (* tags){where('tags @> ARRAY[?]', tags)}
end
~~~
    
---

Querying Tags in ActiveRecord
------------------------

Find all the hedgehogs that are spiny or large, and older than 4:

~~~ ruby
Hedgehog.any_tags('spiny', 'large').where('age > ?', 4)
~~~

---

> Hi, I run an influential hedgehog club.  Our members would all use [HedgeWith.me](http://hedgewith.me), if they could show which hogs are members of our selective society.
<cite>Boston Spine Fancy President</cite>

Hierarchy
---------

Apparently there are thousands of hedgehog leagues, divisions, societies, clubs, and so forth.

<img src='images/hedgehog_clubs.png' style='width: 200px; position: absolute; left: 300px; bottom: 50px'/>

---

Hierarchy
---------

We need to efficiently model a club hierarchy like this:

* North American League
    * Western Division
        * Cascadia Hog Friends
        * Californian Hedge Society
        
How can we support operations like finding a club's depth, children, or parents?

---

Materialized Path in SQL
-----------------------

Encode the parent ids of each record in its `path`.

~~~ sql
CREATE TABLE clubs (
    id              integer primary key,
    name            text,
    path            integer[]
);
~~~

---

Querying a Materialized Path
-----------------------


id |           name            |    <span style='width:12em; display: block;'>path</span>
---|---------------------------|--------
 1 | <span style='padding-left: 0em;'>North American League  <span/> | [1]
 2 | <span style='padding-left: 2em;'>Eastern Division       <span/> | [1,2]
 4 | <span style='padding-left: 4em;'>New York Quillers      <span/> | [1,2,4]
 5 | <span style='padding-left: 4em;'>Boston Spine Fancy     <span/> | [1,2,5]
 3 | <span style='padding-left: 2em;'>Western Division       <span/> | [1,3]
 6 | <span style='padding-left: 4em;'>Cascadia Hog Friends   <span/> | [1,3,6]
 7 | <span style='padding-left: 4em;'>California Hedge Society<span/>| [1,3,7]

...

---

Materialized Path: Depth 
------------------------

The depth of each club is simply the length of its path.

* `array_length(array, dim)` &nbsp; returns the length of the array

`dim` will always be 1 unless you are using multidimensional arrays.


---

Materialized Path: Depth 
------------------------

Display the top two tiers of hedgehog clubs:

~~~ sql
SELECT name, path, array_length(path, 1) AS depth 
FROM clubs
WHERE array_length(path, 1) <= 2
ORDER BY path;
~~~

<span class='footnote'>
`array_length(path, 1)` &nbsp; is the depth of record
</span>

---

Materialized Path: Depth  
----------------------


         name          | path  | depth 
-----------------------|-------|-------
 <span style='padding-left: 0em;'>North American League </span> | [1]   |     1
 <span style='padding-left: 2em;'>Eastern Division      </span> | [1,2] |     2
 <span style='padding-left: 2em;'>Western Division      </span> | [1,3] |     2
 <span style='padding-left: 0em;'>South American League </span> | [9]   |     1


---

Materialized Path: Children
-------------------------

Find all the clubs that are children of the California Hedge Society, ID: `7`.

~~~ sql
SELECT id, name, path FROM clubs 
WHERE path && ARRAY[7]
ORDER BY path
~~~

<span class='footnote'>
`A && B` &nbsp; A overlaps any of B
</span>

---

Materialized Path: Children
-------------------------

id |          name             | path   
---|---------------------------|----------- 
 7 | <span style='padding-left: 0em;'>Californian Hedge Society </span>| [1,3,<span class='highlight'>7</span>]
 8 | <span style='padding-left: 2em;'>Real Hogs of the OC       </span>| [1,3,<span class='highlight'>7</span>,8]
12 | <span style='padding-left: 2em;'>Hipster Hogs              </span>| [1,3,<span class='highlight'>7</span>,12]

<span class='footnote'>
Apparently it is [illegal](http://en.wikipedia.org/wiki/Domesticated_hedgehog#cite_note-1) to own hedgehogs in California
</span>

---

Materialized Path: Parents 
------------------------
Find the parents of the California Hedge Society, Path: `ARRAY[1,3,7]`.

~~~ sql
SELECT name, path FROM clubs 
WHERE ARRAY[id] && ARRAY[1,3,7]
ORDER BY path;
~~~

<span class='footnote'>
`A && B` &nbsp; A overlaps any of B
</span>

---

Materialized Path: Parents 
------------------------

id |         name              | path    
---|---------------------------|---------
 1 | <span style='padding-left: 0em;'>North American League     </span>| [1]
 3 | <span style='padding-left: 2em;'>Western Division          </span>| [1,3]
 7 | <span style='padding-left: 4em;'>Californian Hedge Society </span>| [1,3,7]

---

ActiveRecord: Arrays & Depth
------------------------

With ActiveRecord 4.x, `path` is just ruby array.

~~~ ruby
class Club < ActiveRecord::Base
  def depth
    self.path.length
  end
  ...
~~~

---

Querying in ActiveRecord
------------------------
Encapsulate these conditions as instance methods:

~~~ ruby
class Club < ActiveRecord::Base
  def children
    Club.where('path && ARRAY[?]', self.id)
  end
  def parents
    Club.where('ARRAY[id] && ARRAY[?]', self.path)
  end
~~~

---

Querying in ActiveRecord
------------------------

Now we have an easy way to query the hierarchy.

~~~ ruby
@club.parents.limit(5)
@club.children.joins(:hedgehogs).merge(Hedgehog.any_tags('silly'))
~~~

These features can all work together.

<span class='footnote'>
  Mind blown?
</span>

---

> I need to keep track of my hedgehogs' favorite foods, colors, weight, eye color, and shoe sizes!
<cite>the Quantified Hedgehog Owner</cite>

> If I am forced to enter my hedgehog's shoe size, I will quit immediately!
<cite>the Unquantified Hedgehog Owner</cite>

Custom Data 
-----------
Your users want to record arbitrary data about their hedgehogs.

<img src='images/hedgehog_data.png' style='width: 400px; position: absolute; right: 100px; bottom: 150px'/>

---

Hstore
------

Hstore provides a hash column type.  It is a useful alternative to ActiveRecord's `serialize` where the keys and values can be queried in Postgres.

---

Hstore
------

Hstore needs to be installed manually.  Your migration will look like this:

~~~ ruby
class InstallHstore < ActiveRecord::Migration
  def up
    execute 'CREATE EXTENSION hstore'
  end
  ...
~~~

---

Heads Up 
--------
Although hstore is supported by ActiveRecord 4.x, the default schema format does not support extensions.

Update `config/application.rb` to use the SQL schema format, otherwise your tests will fail.

~~~ ruby
class Application < Rails::Application
  config.active_record.schema_format = :sql
end
~~~

---

Defining an Hstore in SQL
----------------------

~~~ sql
CREATE TABLE hedgehogs (
    id      integer primary key,
    name    text,
    age     integer,
    tags    text[],
    custom  hstore DEFAULT '' NOT NULL
);
~~~

---

Defining an Hstore in ActiveRecord
--------------------------------

`hstore` is supported in ActiveRecord 4.x as a normal column type:

~~~ ruby
create_table :hedgehogs do |t|
  t.string  :name
  t.integer :age
  t.text    :tags, array: true
  t.hstore  :custom, :default => '', :null => false
end
~~~


---

Heads Up 
--------

Save yourself some hassle, and specify an empty hstore by default: 

<pre><code class='ruby'>t.hstore  :custom, <span class='highlight'>:default => '', :null => false</span></code></pre>

Otherwise new records will have null hstores.

---

Hstore Format 
-------------

Hstore uses a text format, it looks a lot like a ruby 1.8 hash:

~~~ sql
UPDATE hedgehogs SET 
custom = '"favorite_food" => "lemons", "weight" => "2lbs"'  
WHERE id = 1;
~~~

Be careful of quoting.

---

Hstore Operators 
-------------

Common functions and operators:

* `defined(A, B)` &nbsp; Does A have B?
* `A -> B` &nbsp; Get B from A.  In ruby this would be A[B]

---

Query Hstore in SQL 
-------------------

Find all the favorite foods of the hedgehogs:

~~~ sql
SELECT name, custom -> 'favorite_food' AS food 
FROM hedgehogs WHERE defined(custom, 'favorite_food');
~~~

<span class='footnote'>
  `defined(A, B)` &nbsp; Does A have B?<br/>
  `A -> B` &nbsp; Get B from A.  In ruby this would be A[B]
</span>

---

Query Hstore in SQL 
-------------------


name    |  food  
--------|-------
Horrace | lemons
Quilby  | pasta
Thomas  | grubs

---

Query Hstore in ActiveRecord
-------------------
Create scopes to make querying easier:

~~~ ruby
class Hedgehog < ActiveRecord::Base
  scope :has_key,   -> (key){ where('defined(custom, ?)', key) }
  scope :has_value, -> (key, value){ where('custom -> ? = ?', key, value) }
  ...
~~~

---

Query Hstore in ActiveRecord
-------------------

Find hedgehogs with a custom `color`:

~~~ ruby
Hedgehog.has_key('color')
~~~

---

Query Hstore in ActiveRecord
-------------------

Find hedgehogs that are brown:

~~~ ruby
Hedgehog.has_value('color', 'brown')
~~~

---

Query Hstore in ActiveRecord
-------------------

Find all the silly, brown, hedgehogs:

~~~ ruby
Hedgehog.any_tags('silly').has_value('color', 'brown')
~~~

---

Updating an Hstore with ActiveRecord 
------------------------------------

With ActiveRecord 4.x, hstore columns are just hashes:

~~~ ruby
hedgehog.custom["favorite_color"] = "ochre"
hedgehog.custom = {favorite_food: "Peanuts", shoe_size: 3}
~~~

---

Heads Up 
--------
Hstore columns are always stored as strings:

~~~ ruby
hedgehog.custom["weight"] = 3
hedgehog.save!
hedgehog.reload
hedgehog.custom['weight'].class #=> String
~~~

---


> Someone commented on my hedgehog.  They said they enjoy his beady little eyes, but I can't find it.
<cite>hog_mama_73</cite>

Full Text Search 
----------------

Your users want to be able to search within their comments.

<img src='images/hedgehog_comment.png' style='width: 250px; position: absolute; right: 300px; bottom: 80px'/>

---

Full Text Search in SQL 
--------------------------

~~~ sql
CREATE TABLE comments (
    id              integer primary key,
    hedgehog_id     integer,
    body            text
);
~~~

---

Full Text Search Data Types
----------------

There are two important data types:

* `tsvector` &nbsp; represents the text to be searched
* `tsquery` &nbsp; represents the search query

---

Full Text Search Functions
----------------

There are two main functions that convert strings into these types:

* `to_tsvector(configuration, text)` &nbsp; creates a normalized `tsvector`
* `to_tsquery(configuration, text)` &nbsp; creates a normalized `tsquery`

---

Full Text Search Normalization
----------------

Postgres removes common stop words:

~~~ sql
select to_tsvector('A boy and his hedgehog went to Portland');
-- boy, hedgehog, portland, went

select to_tsvector('I need a second line to fill space here.');
-- fill, line, need, second, space
~~~

---

Full Text Search Normalization
----------------

Stemming removes common endings from words:

   term   | stemmed
----------|------------
hedgehogs | hedgehog
enjoying  | enjoy
piping    | pipe

---

Full Text Search Operators 
----------------

Vectors:

* `V @@ Q` &nbsp; Searches V for Q

Queries: 

* `V @@ (A && B)` &nbsp; Searches V for A and B
* `V @@ (A || B)` &nbsp; Searches V for A or B

---

Full Text Search Querying
--------

Find comments about "enjoying" something:

~~~ sql
SELECT body 
FROM comments 
WHERE to_tsvector('english', body) 
  @@  to_tsquery('english','enjoying');
~~~

<span class='footnote'>
`V @@ Q` &nbsp; Searches V for Q
</span>

---

Full Text Search Querying
--------

* Does he <span class='highlight'>enjoy</span> beets?  Mine loves them                           
* I really <span class='highlight'>enjoy</span> oranges                                          
* I am <span class='highlight'>enjoying</span> these photos of your hedgehog's beady little eyes
* Can I feed him grapes? I think he <span class='highlight'>enjoys</span> them.                  


Notice how "enjoying" also matched "enjoy" and "enjoys" due to stemming.

---

Full Text Search Wildcards
---------------------------

* `to_tsquery('english','cat:*')` &nbsp; Searches for anything starting with cat

Such as: <span class='highlight'>cat</span>, <span class='highlight'>cat</span>apult, <span class='highlight'>cat</span>aclysmic.

But not: octo<span class='not-highlight'>cat</span>, s<span class='not-highlight'>cat</span>ter, prognosti<span class='not-highlight'>cat</span>e


---

Full Text Search Wild Cards
--------

Find comments containing the term "oil", and a word starting with "quil" :

~~~ sql
SELECT body 
FROM comments 
WHERE to_tsvector('english', body) 
  @@ ( to_tsquery('english','oil') 
    && to_tsquery('english','quil:*')
  );
~~~

<span class='footnote'>
`V @@ (A && B)` &nbsp; Searches V for A and B
</span>

---

Full Text Search Querying
--------

* What brand of <span class='highlight'>oil</span> do you use?  Have you tried <span class='highlight'>Quill</span>Swill?

---

Heads Up
-------- 
`tsquery` only supports wildcards at the end of a term. 

While `quill:*` will match "QuillSwill", but `*:swill` will not.

In fact, `*:swill` will throw an error.

---

Even More Heads Up!
--------
Never pass user input directly to `to_tsquery`, it has a strict mini search syntax.  The following all fail:

* `http://localhost` &nbsp; `:` has a special meaning 
* `O'Reilly's Books` &nbsp; Paired quotes cannot be in the middle
* `A && B` &nbsp; `&` and `|` are used for combining terms

You need to sanitize queries, or use a gem that does this for you.

---

Full Text Search With ActiveRecord
--------
We can wrap this up in a scope.

~~~ ruby
class Comment < ActiveRecord::Base
  scope :search_all, -> (query){ 
    where("to_tsvector('english', body) @@ #{sanitize_query(query)}")
  }
~~~

<span class='footnote'>
You need to write `sanitize_query`, or use a gem that does this for you.
</span>

---

Full Text Search With ActiveRecord
--------

Find the comments about quill oil again, and limit it to 5 results:

~~~ ruby
Comment.search_all("quil* oil").limit(5)
~~~

Since `search_all` is a scope, we chain it like all the other examples.

---

Full Text Search Indexing 
--------------------------

Create an index on the function call `to_tsvector('english', body)`:

~~~ sql
CREATE INDEX comments_gin_index 
ON comments 
USING gin(to_tsvector('english', body));
~~~

The `gin` index is a special index for multivalued columns like a `text[]` or a `tsvector`

---

Heads Up
--------

Since we are indexing a function call, `to_tsvector('english', body)`, we must call it the same way every time.

<span class='footnote'>
  You don't have to use `english`, but you do need to be consistent.
</span>

---

In Summary
----------

* Arrays can model tagging and hierarchies
* Hstore can be used to model custom data
* Postgres supports full text search

You can now enjoy the happy hour!

~~~ sql
SELECT * FROM beers WHERE
traits @> ARRAY['hoppy', 'floral']
~~~

---

Any Questions?
------

Possible suggestions:

* Why not normalize your database instead of using arrays?
* Can I see how you implemented `sanitize_query`?
* What is a good gem for full text search?
* What about ActiveRecord 2 and 3?
* Why hstore instead of JSON?
* Can I buy you coffee?

---

Extra Resources
---------------

* ActiveRecord [Queries & Scopes](http://edgeguides.rubyonrails.org/active_record_querying.html#scopes)
* Postgres [Array Operators](http://www.postgresql.org/docs/9.2/static/functions-array.html)
* Postgres [Hstore Documentation](http://www.postgresql.org/docs/9.2/static/hstore.html)
* Postgres [Full Text Search](http://www.postgresql.org/docs/9.2/static/textsearch.html)
* Ruby Gems for Full Text Search 
    * [Textacular](https://github.com/textacular/textacular/) Supports Active Record 2.x and 3.x
    * [pg_search](https://github.com/Casecommons/pg_search/) Supports Active Record 3.x, but has more features
* My [Blog](http://monkeyandcrow.com), [Github](http://github.com/adamsanderson), and [favorite social network](http://hedgewith.me)
* [How to draw a hedgehog](http://www.janbrett.com/how_to_draw_a_hedgehog.htm).

---

Bonus
-----
Here's `sanitize_query`:

~~~ ruby
def self.sanitize_query(query, conjunction=' && ')
  "(" + tokenize_query(query).map{|t| term(t)}.join(conjunction) + ")"
end
~~~

It breaks up the user's request into terms, and then joins them together.

---

Bonus 
-----

We tokenize by splitting on white space, `&`, `|`, and `:`.

~~~ ruby
def self.tokenize_query(query)
  query.split(/(\s|[&|:])+/)
end
~~~

---

Bonus
-----
Each of those tokens gets rewritten:

~~~ ruby
def self.term(t)
  # Strip leading apostrophes, they are never legal, "'ok" becomes "ok"
  t = t.gsub(/^'+/,'')
  # Strip any *s that are not at the end of the term
  t = t.gsub(/\*[^$]/,'')
  # Rewrite "sear*" as "sear:*" to support wildcard matching on terms
  t = t.gsub(/\*$/,':*')
  ...
~~~

---

~~~ ruby
  ...
  # If the only remaining text is a wildcard, return an empty string
  t = "" if t.match(/^[:* ]+$/)
  
  "to_tsquery('english', #{quote_value t})"
end
~~~
