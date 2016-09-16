SS::Application.routes.draw do

  Recommend::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, :on => :collection
  end

  namespace "recommend", path: ".s:site/recommend" do
    namespace "history" do
      get "receiver" => "receiver#index", as: "receiver"
      resources :logs, concerns: [:deletion]
    end
  end

  part "recommend" do
    get "history" => "public#index", cell: "parts/history"
    get "recommend" => "public#index", cell: "parts/recommend"
  end

end
