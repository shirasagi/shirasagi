SS::Application.routes.draw do
  Gws::StaffRecord::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws "staff_record" do
    resources :public_records, only: [:index, :show]
    resources :public_duties, only: [:index, :show]
    resource :setting, only: [:show, :edit, :update]
    resources :years, concerns: [:deletion]
    resources :groups, concerns: [:deletion]
    resources :users, concerns: [:deletion]
  end
end
