class Photo < ActiveRecord::Base
  belongs_to :album

  mount_uploader :image, ImageUploader

  validates_presence_of :title, :image
end
