Rails.application.routes.draw do
  Gws::Presence::Initializer

  concern :portlet do
    get :portlet, on: :collection
    get :table, on: :collection
  end

  gws "presence" do
    get '/' => redirect { |p, req| "#{req.path}/users" }, as: :main
    resources :users, only: [:index], concerns: [:portlet]
    namespace :group, path: 'g-:group' do
      resources :users, only: [:index], concerns: [:portlet]
    end
    namespace :custom_group, path: 'c-:group' do
      resources :users, only: [:index], concerns: [:portlet]
    end

    namespace "apis" do
      resources :users, only: [:index, :show, :update] do
        get :states, on: :collection
      end
      namespace :group, path: 'g-:group' do
        resources :users, only: [:index, :show, :update]
      end
      namespace :custom_group, path: 'c-:group' do
        resources :users, only: [:index, :show, :update]
      end
    end

    resource :user_setting, only: [:show, :edit, :update]
  end
end
