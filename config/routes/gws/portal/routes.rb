SS::Application.routes.draw do
  Gws::Portal::Initializer

  concern :deletion do
    get :delete, on: :member
    #delete action: :destroy_all, on: :collection
  end

  concern :portlet do
    get :reset, on: :collection
    post :reset, on: :collection
  end

  gws "portal" do
    namespace :user, path: 'u-:user' do
      get '/' => 'portal#show'
      resources :portlets, concerns: [:deletion, :portlet]
      resource :settings, concerns: [:deletion], only: [:show, :edit, :update]
      resource :layouts, concerns: [:deletion], only: [:show, :update]
    end

    namespace :group, path: 'g-:group' do
      get '/' => 'portal#show'
      resources :portlets, concerns: [:deletion, :portlet]
      resource :settings, concerns: [:deletion], only: [:show, :edit, :update]
      resource :layouts, concerns: [:deletion], only: [:show, :update]
    end

    namespace :setting do
      resources :users, only: [:index]
      resources :groups, only: [:index]
    end
  end
end
