SS::Application.routes.draw do
  Gws::Notice::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  namespace "gws", path: ".g:site/gws" do
    resources :notices, concerns: [:deletion]
    resources :public_notices, only: [:index, :show]
  end
end
