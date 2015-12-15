SS::Application.routes.draw do
  Gws::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  get '.g:site/', to: 'gws/portal#index', as: :gws_portal

  namespace "gws", path: ".g:site/gws" do
    resource  :site
    resources :users, concerns: [:deletion]
    resources :roles, concerns: [:deletion]
    resources :facilities, concerns: [:deletion]
    resources :notices, concerns: [:deletion]
    resources :public_notices, concerns: [:deletion]

    namespace "apis" do
      get "groups" => "groups#index"
    end
  end
end
