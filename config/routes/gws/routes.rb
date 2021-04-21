Rails.application.routes.draw do
  Gws::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :collection
    get :download_template, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :webmail_import do
    get :webmail_import, on: :collection
    post :webmail_import, on: :collection
  end

  concern :lock_and_unlock do
    post :lock_all, on: :collection
    post :unlock_all, on: :collection
  end

  namespace "gws", path: ".g:site" do
    get "/", to: "portal/main#show", as: :portal
    match "logout" => "login#logout", as: :logout, via: [:get, :delete]
    match "login" => "login#login", as: :login, via: [:get, :post]
    post "access_token" => "login#access_token", as: :access_token
  end

  namespace "gws", path: ".g:site/gws" do
    get "default_groups/:default_group" => "default_groups#update", as: :default_group
    get "question_management" => "question_management#index"
    resource  :site
    resources :groups, concerns: [:deletion, :download, :import]
    resources :custom_groups, concerns: [:deletion]
    resources :users, concerns: [:deletion, :download, :import, :webmail_import, :lock_and_unlock]
    resources :user_titles, concerns: [:deletion] do
      match :download_all, on: :collection, via: %i[get post]
      match :import, on: :collection, via: %i[get post]
    end
    resources :roles, concerns: [:deletion, :download, :import]
    resources :sys_notices, only: [:index, :show]
    resources :links, concerns: [:deletion]
    resources :public_links, only: [:index, :show]
    resources :histories, only: [:index]
    resources :histories, only: [:index, :show], path: 'histories/:ymd', as: :daily_histories do
      match :download, on: :collection, via: [:get, :post]
    end
    resources :history_archives, concerns: [:deletion], only: [:index, :show, :destroy]
    resource :user_profile, only: [:show]
    resource :user_setting, only: [:show, :edit, :update]
    resource :user_form, concerns: [:deletion] do
      resources :user_form_columns, concerns: :deletion, path: '/columns'
    end
    resources :contrasts, concerns: [:deletion]

    namespace "apis" do
      get "groups" => "groups#index"
      get "users" => "users#index"
      get "user_titles" => "user_titles#index"
      get "facilities" => "facilities#index"
      post "reminders" => "reminders#create"
      delete "reminders" => "reminders#destroy"
      post "reminders/restore" => "reminders#restore", as: :restore_reminder
      post "reminders/notifications" => "reminders#notification"
      get "custom_groups" => "custom_groups#index"
      get "contrasts" => "contrasts#index"
      get "desktop_settings" => "desktop_settings#index"
      put "reload_site_usages" => "site_usages#reload"
      post "validation" => "validation#validate"

      resources :files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
      end
    end
  end

  gws "reminder" do
    get '/' => redirect { |p, req| "#{req.path}/-/items" }, as: :main
    scope path: ':mode' do
      resources :items, only: [:index, :destroy], concerns: [:deletion] do
        get :redirect, on: :member
      end
    end
  end
end
