SS::Application.routes.draw do
  Gws::Facility::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws "facility" do
    resources :columns, path: 'items/:form_id/columns', concerns: [:deletion] do
      get :input_form, on: :collection
    end
    resources :items, concerns: [:deletion]
    namespace :usage do
      get '/' => 'main#index', as: :main
      resources :yearly, only: [:index], path: 'yearly/:yyyy', yyyy: %r{\d{4}} do
        get :download, on: :collection
      end
      resources :monthly, only: [:index], path: 'monthly/:yyyymm', yyyymm: %r{\d{6}} do
        get :download, on: :collection
      end
    end
    resources :categories, concerns: [:deletion]
    resource :setting, only: [:show, :edit, :update]
  end
end
