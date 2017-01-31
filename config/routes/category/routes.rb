SS::Application.routes.draw do

  Category::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :integration do
    get :split, :on => :collection
    post :split, :on => :collection
    get :integrate, :on => :collection
    post :integrate, :on => :collection
  end

  content "category" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    resources :nodes, concerns: [:deletion, :integration]
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
