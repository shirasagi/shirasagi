SS::Application.routes.draw do

  Recommend::Initializer

  concern :deletion do
    get :delete, :on => :member
    #delete action: :destroy_all, on: :collection
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

end
