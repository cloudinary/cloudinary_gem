class Album < ActiveRecord::Base
  has_many :photos, -> { order('created_at DESC') }

  def cover
    photos.first
  end
end
