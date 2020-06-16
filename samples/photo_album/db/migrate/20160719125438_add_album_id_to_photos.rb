class AddAlbumIdToPhotos < ActiveRecord::Migration[4.2]
  def change
    add_column :photos, :album_id, :integer
  end
end
