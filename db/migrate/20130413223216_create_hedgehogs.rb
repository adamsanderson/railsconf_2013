class CreateHedgehogs < ActiveRecord::Migration
  def change
    create_table :hedgehogs do |t|
      t.string  :name
      t.integer :age
      # Use text instead of varchar, postgres assumes string arrays
      # are text by default, this means less casting.
      t.text    :tags, array: true
      
      t.timestamps
    end
  end
end
