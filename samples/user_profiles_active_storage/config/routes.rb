Rails.application.routes.draw do
  resources :users do
    resources :photos, only: [:index, :show, :destroy]
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
