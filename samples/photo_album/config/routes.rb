PhotoAlbum::Application.routes.draw do

  resources :photos, :only => [:index, :new, :create]
  
  root :to => 'photos#index'
  
end