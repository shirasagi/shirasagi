# coding: utf-8
SS::Application.routes.draw do

  Facility::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "facility" do
    get "/" => "main#index", as: :main
    resources :facilities, concerns: :deletion
    resources :images, concerns: :deletion
    resources :maps, concerns: :deletion
  end

  node "facility" do
    get "facility/(index.:format)" => "public#index", cell: "nodes/facility"
    get "facility/rss.xml" => "public#rss", cell: "nodes/facility", format: "xml"

    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "node/rss.xml" => "public#rss", cell: "nodes/node", format: "xml"

    get "search/(index.:format)" => "public#index", cell: "nodes/search"
    get "search/(search.:format)" => "public#search", cell: "nodes/search"
  end

  namespace "facility", path: ".:site/facility" do
    get "/search_categories" => "search_categories#index"
    post "/search_categories" => "search_categories#search"
    get "/search_locations" => "search_locations#index"
    post "/search_locations" => "search_locations#search"
    get "/search_uses" => "search_uses#index"
    post "/search_uses" => "search_uses#search"
  end

end
