class PhotosController < ApplicationController

  def index
    @photos = Photo.order("created_at desc").to_a
  end

  def new
    @photo = Photo.new(:title => "My photo \##{1 + (Photo.maximum(:id) || 0)}")
    render view_for_new
  end

  def create
    @photo = Photo.new(params[:photo])
    # In through-the-server mode, the image is first uploaded to the Rails server.
    # When @photo is saved, Carrierwave uploads the image to Cloudinary.
    # The upload metadata (e.g. image size) is then available in the
    # uploader object of the model (@photo.image).
    # In direct mode, the image is uploaded to Cloudinary by the browser,
    # and upload metadata is available in JavaScript (see new_direct.html.erb).
    if !@photo.save
      @error = @photo.errors.full_messages.join('. ')
      render view_for_new
      return
    end
    if !direct_upload_mode?
      # In this sample, we want to store a part of the upload metadata
      # ("bytes" - the image size) in the Photo model.
      # In direct mode, we pass the image size via a hidden form field
      # filled by JavaScript (see new_direct.html.erb).
      # In through-the-server mode, we need to copy this field from Cloudinary
      # upload metadata. The metadata is only available after Carrierwave
      # performs the upload (in @photo.save), so we need to update the
      # already saved photo here.
      @photo.update_attributes(:bytes => @photo.image.metadata['bytes'])
      # Show upload metadata in the view
      @upload = @photo.image.metadata
    end
  end

  protected
  
  def direct_upload_mode?
    params[:direct].present?
  end
  
  def view_for_new
    direct_upload_mode? ? "new_direct" : "new"
  end

end