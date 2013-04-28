class AddHstoreExtension < ActiveRecord::Migration
  def up
    # ActiveRecord does not have any migration support for extensions, use an execute.
    # This will NOT be reflected in schema.rb
    execute 'CREATE EXTENSION hstore'
  end
  
  def down
    execute 'DROP EXTENSION hstore'
  end
end
