SS::Application.routes.draw do
  Gws::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  get '.g:site/', to: 'gws/portal#index', as: :gws_portal

  namespace "gws", path: ".g:site/gws" do
    get "default_groups/:default_group" => "default_groups#update", as: :default_group
    resource  :site
    resources :groups, concerns: [:deletion]
    resources :custom_groups, concerns: [:deletion]
    resources :users, concerns: [:deletion]
    resources :user_titles, concerns: [:deletion]
    resources :roles, concerns: [:deletion]
    resources :notices, concerns: [:deletion]
    resources :public_notices, only: [:index, :show]
    resources :links, concerns: [:deletion]
    resources :public_links, only: [:index, :show]
    resources :reminders, only: [:index, :destroy], concerns: [:deletion]
    resources :histories, only: [:index]
    resource :system_setting, only: [:show, :edit, :update]
    resource :user_setting, only: [:show, :edit, :update]

    namespace "apis" do
      get "groups" => "groups#index"
      get "users" => "users#index"
      get "facilities" => "facilities#index"
      post "reminders" => "reminders#create"
      delete "reminders" => "reminders#destroy"
      post "reminders/notifications" => "reminders#notification"
      get "custom_groups" => "custom_groups#index"

      resources :files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
      end
    end
  end
end
