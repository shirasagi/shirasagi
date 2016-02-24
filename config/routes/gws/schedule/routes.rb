SS::Application.routes.draw do
  Gws::Schedule::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  gws "schedule" do
    resources :holidays, concerns: [:deletion]
    resources :categories, concerns: [:deletion]
    resources :plans, concerns: [:deletion]
    resources :list_plans, concerns: [:deletion]
    resources :user_plans, path: 'user/:user/plans', concerns: [:deletion]
    get 'groups' => 'groups#index'
    resources :group_plans, path: 'group/:group/plans', concerns: [:deletion]
    get 'facilities' => 'facilities#index'
    resources :facility_plans, path: 'facility/:facility/plans', concerns: [:deletion]
    #resources :facility_group_plans, path: 'fg:group/plans', concerns: [:deletion]
  end
end
