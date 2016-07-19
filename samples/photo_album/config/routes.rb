PhotoAlbum::Application.routes.draw do
  resources :albums do
    resources :photos, :only => [:index, :new, :create]
  end

  root :to => 'albums#index'
end
