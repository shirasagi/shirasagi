SS::Application.routes.draw do
  Gws::Schedule::Initializer

  concern :plans do
    get :popup, on: :member
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  gws "schedule" do
    get 'all_groups' => 'groups#index'
    get 'facilities' => 'facilities#index'
    resources :holidays, concerns: :plans
    resources :categories, concerns: :plans
    resources :plans, concerns: :plans
    resources :list_plans, concerns: :plans
    resources :user_plans, path: 'users/:user/plans', concerns: :plans
    resources :group_plans, path: 'groups/:group/plans', concerns: :plans
    resources :custom_group_plans, path: 'custom_groups/:group/plans', concerns: :plans
    resources :facility_plans, path: 'facilities/:facility/plans', concerns: :plans
    #resources :facility_group_plans, path: 'fg:group/plans', concerns: :plans

    resource :setting, only: [:show, :edit, :update]
  end
end
