SS::Application.routes.draw do
  Gws::Schedule::Initializer

  concern :plans do
    get :events, on: :collection
    get :print, on: :collection
    get :popup, on: :member
    get :copy, on: :member
    match :soft_delete, on: :member, via: [:get, :post]
  end

  concern :export do
    get :download, on: :collection
  end

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  gws "schedule" do
    get 'all_groups' => 'groups#index'
    get 'facilities' => 'facilities#index'
    get 'facilities/print' => 'facilities#print'
    get 'search' => redirect { |p, req| "#{req.path}/users" }, as: :search
    get 'search/users' => 'search/users#index', as: :search_users
    get 'search/times' => 'search/times#index', as: :search_times
    get 'search/reservations' => 'search/reservations#index', as: :search_reservations
    get 'csv' => 'csv#index', as: :csv
    post 'import_csv' => 'csv#import', as: :import_csv

    get '/' => redirect { |p, req| "#{req.path}/plans" }, as: :main
    resources :plans, concerns: [:plans, :export], except: [:destroy]
    resources :list_plans, concerns: :plans
    resources :user_plans, path: 'users/:user/plans', concerns: :plans
    resources :group_plans, path: 'groups/:group/plans', concerns: :plans
    resources :custom_group_plans, path: 'custom_groups/:group/plans', concerns: :plans
    resources :facility_plans, path: 'facilities/:facility/plans', concerns: [:plans, :export]
    resources :trashes, concerns: [:deletion], except: [:new, :create, :edit, :update] do
      match :undo_delete, on: :member, via: [:get, :post]
    end
    resources :holidays, concerns: [:plans, :deletion]
    resources :comments, path: ':plan_id/comments', only: [:create, :edit, :update, :destroy], concerns: :deletion
    resource :attendance, path: ':plan_id/:user_id/attendance', only: [:edit, :update]
    resource :approval, path: ':plan_id/:user_id/approval', only: [:edit, :update]

    namespace 'todo' do
      get '/' => redirect { |p, req| "#{req.path}/readables" }, as: :main
      resources :readables, concerns: :plans do
        match :finish, on: :member, via: %i[get post]
        match :revert, on: :member, via: %i[get post]
        post :finish_all, on: :collection
        post :revert_all, on: :collection
        post :soft_delete_all, on: :collection
      end
      resources :trashes, concerns: :deletion do
        match :undo_delete, on: :member, via: %i[get post]
        post :undo_delete_all, on: :collection
      end
    end

    resources :categories, concerns: :deletion
    resource :user_setting, only: [:show, :edit, :update]
  end
end
