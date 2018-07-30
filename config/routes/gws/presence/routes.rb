SS::Application.routes.draw do
  Gws::Presence::Initializer

  concern :table do
    get :table, on: :collection
  end

  concern :portlet do
    get :portlet, on: :collection
  end

  gws "presence" do
    get '/' => redirect { |p, req| "#{req.path}/users" }, as: :main
    resources :users, only: [:index], concerns: [:table]
    namespace :group, path: 'g-:group' do
      resources :users, only: [:index], concerns: [:table, :portlet]
    end
    namespace :custom_group, path: 'c-:group' do
      resources :users, only: [:index], concerns: [:table, :portlet]
    end

    namespace "apis" do
      resources :users, only: [:index, :show, :update]
      namespace :group, path: 'g-:group' do
        resources :users, only: [:index, :show, :update]
      end
      namespace :custom_group, path: 'c-:group' do
        resources :users, only: [:index, :show, :update]
      end
    end

    namespace 'management' do
      get '/' => redirect { |p, req| "#{req.path}/users" }, as: :main
      resources :users, only: [:index, :show, :edit, :update], concerns: [:table]
      namespace :group, path: 'g-:group' do
        resources :users, only: [:index, :show, :edit, :update], concerns: [:table]
      end
      namespace :custom_group, path: 'c-:group' do
        resources :users, only: [:index, :show, :edit, :update], concerns: [:table]
      end
    end

    resource :user_setting, only: [:show, :edit, :update]
  end
end
