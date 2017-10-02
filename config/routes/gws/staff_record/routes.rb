SS::Application.routes.draw do
  Gws::StaffRecord::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :export do
    get :download, on: :collection
    get :import, on: :collection
    post :import, on: :collection
  end

  gws "staff_record" do
    resources :public_records, only: [:index, :show]
    resources :public_duties, only: [:index, :show, :edit, :update] do
      get :edit_charge, on: :member
      put :update_charge, on: :member
    end
    resources :public_seatings, only: [:index]

    resource :setting, only: [:show, :edit, :update]
    resources :years, concerns: [:deletion]
    resources :groups, path: ':year/groups', concerns: [:deletion, :export]
    resources :users, path: ':year/users', concerns: [:deletion, :export]
    resources :seatings, path: ':year/seatings', concerns: [:deletion, :export]
  end
end
