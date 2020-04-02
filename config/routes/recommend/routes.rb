Rails.application.routes.draw do

  Recommend::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  content "recommend" do
    get "/" => redirect { |p, req| "#{req.path}/receivers" }, as: :main
    resources :receivers, concerns: :deletion
  end

  namespace "recommend", path: ".s:site/recommend" do
    namespace "history" do
      get "receiver" => "receiver#index", as: "receiver"
      get "logs/tokens" => "logs#tokens"
      get "logs/paths" => "logs#paths"
    end

    get "similarity_scores" => "similarity_scores#index"
  end

  part "recommend" do
    get "history" => "public#index", cell: "parts/history"
    get "similarity" => "public#index", cell: "parts/similarity"
  end

  node "recommend" do
    get "receiver/index.json" => "public#index", cell: "nodes/receiver"
  end

end
