SS::Application.routes.draw do
  Gws::Schedule::Initializer

  concern :plans do
    get :events, on: :collection
    get :print, on: :collection
    get :popup, on: :member
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, on: :collection
  end

  gws "schedule" do
    get 'all_groups' => 'groups#index'
    get 'facilities' => 'facilities#index'
    get 'facilities/print' => 'facilities#print'
    get 'search' => redirect { |p, req| "#{req.path}/users" }, as: :search
    get 'search/users' => 'search/users#index', as: :search_users
    get 'search/times' => 'search/times#index', as: :search_times
    get 'search/reservations' => 'search/reservations#index', as: :search_reservations

    get '/' => redirect { |p, req| "#{req.path}/plans" }, as: :main
    resources :plans, concerns: :plans
    resources :list_plans, concerns: :plans
    resources :user_plans, path: 'users/:user/plans', concerns: :plans
    resources :group_plans, path: 'groups/:group/plans', concerns: :plans
    resources :custom_group_plans, path: 'custom_groups/:group/plans', concerns: :plans
    resources :facility_plans, path: 'facilities/:facility/plans', concerns: :plans
    resources :holidays, concerns: :plans
    resources :comments, path: ':plan_id/comments', only: [:create, :edit, :update, :destroy], concerns: :deletion
    resource :attendance, path: ':plan_id/:user_id/attendance', only: [:edit, :update]

    resources :todos, concerns: :plans do
      get :finish, on: :member
      get :revert, on: :member
      post :finish_all, on: :collection
      post :revert_all, on: :collection
      get :disable, on: :member
      post :disable_all, on: :collection
    end
    resources :todo_management do
      get :delete, on: :member
      get :recover, on: :member
      get :active, on: :member
      post :active_all, on: :collection
    end

    resources :categories, concerns: :plans
    resource :user_setting, only: [:show, :edit, :update]
  end
end
