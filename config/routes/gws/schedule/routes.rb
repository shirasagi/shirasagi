SS::Application.routes.draw do
  Gws::Schedule::Initializer

  gws "schedule" do
    resources :calendars do
      get :delete, on: :member
    end
    resources :plans do
      get :delete, on: :member
    end
    resources :facilities do
      get :delete, on: :member
    end
    resources :categories do
      get :delete, on: :member
    end
  end
end
