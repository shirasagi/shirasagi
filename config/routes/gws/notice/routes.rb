SS::Application.routes.draw do
  Gws::Notice::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'notice' do
    resources :readables, only: [:index, :show]
    resources :editables, concerns: [:deletion]
    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
    end
  end
end
