class AddClubIdToHedgehogs < ActiveRecord::Migration
  def change
    add_column :hedgehogs, :club_id, :integer
  end
end
