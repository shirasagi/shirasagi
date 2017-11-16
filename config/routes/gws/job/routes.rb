SS::Application.routes.draw do
  Gws::Share::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws "job" do
    resources :logs, only: [:index, :show] do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      get :download, on: :collection
      post :download, on: :collection
    end

    resources :reservations, only: [:index, :show, :destroy], concerns: [:deletion]
  end
end
