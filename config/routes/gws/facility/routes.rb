SS::Application.routes.draw do
  Gws::Facility::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  gws "facility" do
    resources :items, concerns: [:deletion]
    resources :categories, concerns: [:deletion]
  end
end
