SS::Application.routes.draw do

  Category::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :trash do
    get :trash, on: :collection
    delete :trash, action: :destroy_all, on: :collection
    match :soft_delete, on: :member, via: [:get, :post]
    match :undo_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :integration do
    get :split, :on => :collection
    post :split, :on => :collection
    get :integrate, :on => :collection
    post :integrate, :on => :collection
  end

  content "category" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    resources :nodes, concerns: [:deletion, :trash, :integration]
    resources :pages
  end

  node "category" do
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "node/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  part "category" do
    get "node" => "public#index", cell: "parts/node"
  end

end
