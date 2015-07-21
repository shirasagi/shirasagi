SS::Application.routes.draw do

  Faq::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :copy do
    get :copy, :on => :member
    put :copy, :on => :member
  end

  concern :move do
    get :move, :on => :member
    put :move, :on => :member
  end

  concern :lock do
    get :lock, :on => :member
    delete :lock, action: :unlock, :on => :member
  end

  content "faq" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :copy, :move, :lock]
    resources :searches, concerns: :deletion
  end

  content "faq" do
    get "index_approve" => "pages#index_approve"
    get "index_request" => "pages#index_request"
    get "index_ready" => "pages#index_ready"
    get "index_closed" => "pages#index_closed"
  end

  node "faq" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"

    get "search/(index.:format)" => "public#index", cell: "nodes/search"
  end

  part "faq" do
    get "search" => "public#index", cell: "parts/search"
  end

  page "faq" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

end
