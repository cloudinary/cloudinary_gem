class AlbumsController < ApplicationController
  def index
    @albums = Album.all
  end

  def show
    @album = Album.where(id: params[:id]).includes(:photos).first
  end

  def new
    @album = Album.new(:title => "My album \##{1 + (Album.maximum(:id) || 0)}")
  end

  def create
    @album = Album.new(params[:album])

    if !@album.save
      @error = @album.errors.full_messages.join('. ')
      render "new"
      return
    end

    redirect_to @album
  end
end
