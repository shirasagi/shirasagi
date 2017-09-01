SS::Application.routes.draw do
  Gws::StaffRecord::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws "staff_record" do
    resources :public_records, only: [:index, :show]
    resources :public_duties, only: [:index, :show, :edit, :update] do
      get :edit_charge, on: :member
      put :update_charge, on: :member
    end
    resource :setting, only: [:show, :edit, :update]
    resources :years, concerns: [:deletion]
    resources :groups, path: ':year/groups', concerns: [:deletion]
    resources :users, path: ':year/users', concerns: [:deletion]
  end
end
