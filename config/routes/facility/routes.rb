# coding: utf-8
SS::Application.routes.draw do

  Facility::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "facility" do
    get "/" => "main#index", as: :main
    resources :pages, concerns: :deletion
    resources :uses, concerns: :deletion
    resources :locations, concerns: :deletion
    resources :categories, concerns: :deletion

    resources :images, concerns: :deletion
    resources :maps, concerns: :deletion
  end

  node "facility" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
    get "category/(index.:format)" => "public#index", cell: "nodes/category"
    get "use/(index.:format)" => "public#index", cell: "nodes/use"
    get "location/(index.:format)" => "public#index", cell: "nodes/location"

    get "search/(index.:format)" => "public#index", cell: "nodes/search"
    get "search/(map.:format)" => "public#map", cell: "nodes/search"
    get "search/(result.:format)" => "public#result", cell: "nodes/search"
  end

  page "facility" do
    get "image/:filename.:format" => "public#index", cell: "pages/image"
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
