class AddCustomColumn < ActiveRecord::Migration
  def change
    add_column :hedgehogs, :custom, :hstore, :default => '', :null => false
  end
end
