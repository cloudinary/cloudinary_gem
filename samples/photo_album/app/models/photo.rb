class Photo < ActiveRecord::Base
  attr_accessible :title, :bytes, :image, :image_cache
  mount_uploader :image, ImageUploader
  
  validates_presence_of :title, :image
end
