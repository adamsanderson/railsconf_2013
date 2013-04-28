class CreateComments < ActiveRecord::Migration
  def up
    create_table :comments do |t|
      t.integer :hedgehog_id
      t.string  :comment
      
      t.timestamps
    end
    
    # Later versions of ActiveRecord 4.x allow add_index :using => 'gin'
    execute "CREATE INDEX comments_comment_index ON comments USING gin(to_tsvector('english', comment))"
  end
  
  def down
    drop_table :comments
  end
  
end
