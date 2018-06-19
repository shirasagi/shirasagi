SS::Application.routes.draw do

  Garbage::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  content "garbage" do
    get "/" => redirect { |p, req| "#{req.path}/searches" }, as: :main
    resources :pages, concerns: :deletion
    resources :nodes, concerns: [:deletion, :download, :import]
    resources :searches, concerns: :deletion
    resources :categories, concerns: :deletion
  end

  namespace "garbage", path: ".s:site/garbage" do
    namespace "apis" do
      get "categories" => "categories#index"
    end
  end

  node "garbage" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "category/(index.:format)" => "public#index", cell: "nodes/category"

    get "search/(index.:format)" => "public#index", cell: "nodes/search"
    get "search/(result.:format)" => "public#result", cell: "nodes/search"
  end
end
