Rails.application.routes.draw do

  Garbage::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :change_state do
    get :state, on: :member
    put :change_state_all, on: :collection, path: ''
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
    resources :pages, concerns: [:deletion, :change_state]
    resources :nodes, concerns: [:deletion, :download, :import, :change_state]
    resources :searches, concerns: [:deletion, :change_state]
    resources :category_lists, concerns: [:deletion, :download, :import, :change_state]
    resources :categories, concerns: [:deletion, :change_state]
    resources :area_lists, concerns: [:deletion, :download, :import, :change_state]
    resources :areas, concerns: [:deletion, :change_state]
    resources :center_lists, concerns: [:deletion, :download, :import, :change_state]
    resources :centers, concerns: [:deletion, :change_state]
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
  end
end
