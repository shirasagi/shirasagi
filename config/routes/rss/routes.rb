SS::Application.routes.draw do

  Rss::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :crud do
    get :move, :on => :member
    put :move, :on => :member
    get :copy, :on => :member
    put :copy, :on => :member
  end

  content "rss" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :import, :crud]
  end

  # workflow support
  content "rss" do
    get "index_approve" => "pages#index_approve"
    get "index_request" => "pages#index_request"
    get "index_ready" => "pages#index_ready"
    get "index_closed" => "pages#index_closed"
  end

  node "rss" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
  end

  page "rss" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end
end
