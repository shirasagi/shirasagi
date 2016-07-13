SS::Application.routes.draw do
  Gws::Share::Initializer

  gws "job" do
    resources :logs, only: [:index, :show] do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      get :download, on: :collection
      post :download, on: :collection
    end
  end
end
