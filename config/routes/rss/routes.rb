SS::Application.routes.draw do

  Rss::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :import do
    match :import, via: [:get, :post], on: :collection
  end

  content "rss" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :import]
  end

  node "rss" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
  end

  page "rss" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end
end
