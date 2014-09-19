# coding: utf-8
SS::Application.routes.draw do

  Facility::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "facility" do
    get "/" => "main#index", as: :main
    resources :pages, concerns: :deletion
  end

  node "facility" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  page "facility" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

  namespace "facility", path: ".:site/facility" do
    get "/search_categories" => "search_categories#index"
    post "/search_categories" => "search_categories#search"
  end

end
