Rails.application.routes.draw do

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
    get :download_logs, on: :collection
  end

  content "garbage" do
    get "/" => redirect { |p, req| "#{req.path}/searches" }, as: :main
    resources :pages, concerns: :deletion
    resources :nodes, concerns: [:deletion, :download, :import]
    resources :searches, concerns: :deletion
    resources :category_lists, concerns: [:deletion, :download, :import]
    resources :categories, concerns: :deletion
    resources :area_lists, concerns: [:deletion, :download, :import]
    resources :areas, concerns: :deletion
    resources :center_lists, concerns: [:deletion, :download, :import]
    resources :centers, concerns: :deletion
    resources :remark_lists, concerns: [:deletion, :download, :import]
    resources :remarks, concerns: :deletion
  end

  namespace "garbage", path: ".s:site/garbage" do
    namespace "apis" do
      get "categories" => "categories#index"
    end
  end

  node "garbage" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "category_list/(index.:format)" => "public#index", cell: "nodes/category_list"
    get "category/(index.:format)" => "public#index", cell: "nodes/category"
    get "search/(index.:format)" => "public#index", cell: "nodes/search"
    get "search/(result.:format)" => "public#result", cell: "nodes/search"
    get "area_list/(index.:format)" => "public#index", cell: "nodes/area_list"
    get "area/(index.:format)" => "public#index", cell: "nodes/area"
    get "center_list/(index.:format)" => "public#index", cell: "nodes/center_list"
    get "center/(index.:format)" => "public#index", cell: "nodes/center"
    get "remark_list/(index.:format)" => "public#index", cell: "nodes/remark_list"
    get "remark/(index.:format)" => "public#index", cell: "nodes/remark"
  end
end
