Shopifyconnect::Engine.routes.draw do
  get 'sample/js'
  post 'sample/webhook'

  resource :shop do
    member do
      get :install
      get :authorize
    end
  end

  root "shops#show"
end
