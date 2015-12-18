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
    resources :links, concerns: [:deletion]

    namespace "apis" do
      get "groups" => "groups#index"

      resources :files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
      end
    end
  end
end
