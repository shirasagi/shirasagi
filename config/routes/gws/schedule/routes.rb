SS::Application.routes.draw do
  Gws::Schedule::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  gws "schedule" do
    get 'all_groups' => 'groups#index'
    get 'facilities' => 'facilities#index'
    resources :holidays, concerns: [:deletion]
    resources :categories, concerns: [:deletion]
    resources :plans, concerns: [:deletion]
    resources :list_plans, concerns: [:deletion]
    resources :user_plans, path: 'users/:user/plans', concerns: [:deletion]
    resources :group_plans, path: 'groups/:group/plans', concerns: [:deletion]
    resources :facility_plans, path: 'facilities/:facility/plans', concerns: [:deletion]
    #resources :facility_group_plans, path: 'fg:group/plans', concerns: [:deletion]
  end
end
