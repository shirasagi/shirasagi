SS::Application.routes.draw do
  Gws::Presence::Initializer

  gws "presence" do
    get '/' => redirect { |p, req| "#{req.path}/users" }, as: :main
    resources :users, only: [:index]
    namespace :group, path: 'g-:group' do
      resources :users, only: [:index]
    end
    namespace :custom_group, path: 'c-:group' do
      resources :users, only: [:index]
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
      resources :users, only: [:index, :show, :edit, :update]
      namespace :group, path: 'g-:group' do
        resources :users, only: [:index, :show, :edit, :update]
      end
      namespace :custom_group, path: 'c-:group' do
        resources :users, only: [:index, :show, :edit, :update]
      end
    end

    resource :user_setting, only: [:show, :edit, :update]
  end
end
