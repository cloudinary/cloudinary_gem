class PhotosController < ApplicationController
  before_action :set_user
  before_action :set_photo, only: [:show, :destroy]

  # GET /users/1/photos
  def index
  end

  # GET /users/1/photos/abc
  def show
    @downloaded = @photo.download
  end

  # DELETE /users/1/photos/abc
  def destroy
    @photo.purge
    respond_to do |format|
      format.html { redirect_to @user, notice: 'Photo was successfully destroyed.' }
    end
  end

  private
    def set_user
      @user = User.find(params[:user_id])
    end

    def set_photo
      @photo = @user.photos.find(params[:id])
    end
end
