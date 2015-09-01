SS::Application.routes.draw do
  Gws::Schedule::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  gws "schedule" do
    resources :calendars, concerns: [:deletion]
    resources :plans, concerns: [:deletion]
    resources :categories, concerns: [:deletion]
  end
end
