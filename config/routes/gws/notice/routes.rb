SS::Application.routes.draw do
  Gws::Notice::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'notice' do
    get '/' => redirect { |p, req| "#{req.path}/-/-/readables" }, as: :main

    scope path: ':group/:category' do
      resources :readables, only: [:index, :show]
    end

    resources :editables, concerns: [:deletion]
    resources :categories, concerns: [:deletion]

    namespace "apis" do
      get "categories" => "categories#index"
    end
  end
end
