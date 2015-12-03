class CreateTrackBans < ActiveRecord::Migration
  def change
    create_table :track_bans do |t|
      t.integer :track_id
      t.integer :user_id
      t.integer :station_id

      t.timestamps
    end
  end
end
