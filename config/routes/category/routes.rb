SS::Application.routes.draw do

  Category::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "category" do
    get "/" => redirect { |p, req| "#{req.path}/nodes" }, as: :main
    resources :nodes, concerns: :deletion
    resources :pages, concerns: :deletion
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
