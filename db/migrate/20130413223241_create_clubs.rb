class CreateClubs < ActiveRecord::Migration
  def change
    create_table :clubs do |t|
      t.string  :name
      t.integer :path, array: true
      
      t.timestamps
    end
  end
end
