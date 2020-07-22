class CreateAlbums < ActiveRecord::Migration[4.2]
  def change
    create_table :albums do |t|
      t.string :title

      t.timestamps
    end
  end
end
