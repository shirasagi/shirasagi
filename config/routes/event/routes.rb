SS::Application.routes.draw do

  Event::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :crud do
    get :move, on: :member
    put :move, on: :member
    get :copy, on: :member
    put :copy, on: :member
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :contain_links do
    get :contain_links, on: :member
  end

  content "event" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main

    resources :pages, concerns: [:deletion, :crud, :download, :import, :contain_links]
    resources :searches, only: [:index]
  end

  node "event" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/:year:month.:format" => "public#monthly", cell: "nodes/page",
      year: /\d{4}/, month: /\d{2}/
    get "page/:year:month:day.:format" => "public#daily", cell: "nodes/page",
      year: /\d{4}/, month: /\d{2}/, day: /\d{2}/
    get "search/(index.:format)" => "public#index", cell: "nodes/search"
  end

  part "event" do
    get "calendar" => "public#index", cell: "parts/calendar"
    get "search" => "public#index", cell: "parts/search"
  end

  page "event" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
    get "search/(index.:format)" => "public#index", cell: "node/search"
  end

end
