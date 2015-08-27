SS::Application.routes.draw do
  Gws::Share::Initializer

  gws "share" do
    resources :files do
      get :view, on: :member
      get :thumb, on: :member
      get :download, on: :member
      get :delete, on: :member
    end
  end
end
