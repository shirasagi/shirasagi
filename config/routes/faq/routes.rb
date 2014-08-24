# coding: utf-8
SS::Application.routes.draw do

  Faq::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "faq" do
    get "/" => "main#index", as: :main
    resources :pages, concerns: :deletion
  end

  node "faq" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  page "faq" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

end
