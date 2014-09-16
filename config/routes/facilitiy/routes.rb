# coding: utf-8
SS::Application.routes.draw do

  raise "this"

  Facilitiy::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "facilitiy" do
    get "/" => "main#index", as: :main
    resources :pages, concerns: :deletion
  end

  node "facilitiy" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  page "facilitiy" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

end
