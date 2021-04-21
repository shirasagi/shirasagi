Rails.application.routes.draw do

  Rss::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :import do
    match :import, via: [:get, :post], on: :collection
  end

  content "rss" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :import]
    resources :weather_xmls, concerns: [:deletion]
  end

  node "rss" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "weather_xml/(index.:format)" => "public#index", cell: "nodes/weather_xml"
  end

  page "rss" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end
end
