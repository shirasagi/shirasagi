SS::Application.routes.draw do
  Gws::Portal::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws "portal" do
    namespace :my, path: 'my' do
      resources :portlets, concerns: [:deletion]
      resource :settings, concerns: [:deletion], only: [:show, :edit, :update]
      resource :layouts, concerns: [:deletion], only: [:show, :update]
    end

    namespace :user, path: 'u-:user' do
      get '/' => 'portal#show'
      resources :portlets, concerns: [:deletion]
      resource :settings, concerns: [:deletion], only: [:show, :edit, :update]
      resource :layouts, concerns: [:deletion], only: [:show, :update]
    end

    namespace :group, path: 'g-:group' do
      get '/' => 'portal#show'
      resources :portlets, concerns: [:deletion]
      resource :settings, concerns: [:deletion], only: [:show, :edit, :update]
      resource :layouts, concerns: [:deletion], only: [:show, :update]
    end

    namespace :setting do
      resources :users, only: [:index]
      resources :groups, only: [:index]
    end
  end
end
