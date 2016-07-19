class Album < ActiveRecord::Base
  attr_accessible :title

  has_many :photos, :order => 'created_at DESC'

  def cover
    photos.first
  end
end
