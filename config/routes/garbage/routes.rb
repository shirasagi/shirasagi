SS::Application.routes.draw do

  Garbage::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  #concern :download do
  #  get :download, on: :member
  #end

  content "garbage" do
    get "/" => redirect { |p, req| "#{req.path}/searches" }, as: :main
    resources :pages, concerns: :deletion
    resources :nodes, concerns: :deletion
    resources :searches, concerns: :deletion
    resources :categories, concerns: :deletion

    get "download" => "pages#download", as: "pages/download"
    get "import" => "pages#import", as: "pages/import"
    post "import" => "pages#import"

    #post "pages/download" => "pages#download"
  end

  node "garbage" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "category/(index.:format)" => "public#index", cell: "nodes/category"

    get "search/(index.:format)" => "public#index", cell: "nodes/search"
    get "search/(result.:format)" => "public#result", cell: "nodes/search"
  end

  namespace "garbage", path: ".:site/garbage" do
    get "/search_categories" => "search_categories#index"
  end
end
