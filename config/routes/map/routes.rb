SS::Application.routes.draw do

  Map::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "map" do
    get "/" => "main#index", as: :main
    resources :pages, concerns: :deletion
  end

  node "map" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  page "map" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

end
