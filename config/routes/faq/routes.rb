Rails.application.routes.draw do

  Faq::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :copy do
    get :copy, on: :member
    put :copy, on: :member
  end

  concern :move do
    get :move, on: :member
    put :move, on: :member
  end

  concern :lock do
    get :lock, on: :member
    delete :lock, action: :unlock, on: :member
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :command do
    get :command, on: :member
    post :command, on: :member
  end

  concern :contains_urls do
    get :contains_urls, on: :member
  end

  concern :tag do
    post :tag, action: :set_tag_all, on: :collection
    delete :tag, action: :reset_tag_all, on: :collection
  end

  content "faq" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :copy, :move, :lock, :download, :import, :command, :contains_urls, :tag]
    resources :searches, concerns: :deletion
  end

  content "faq" do
    get "index_approve" => "pages#index_approve"
    get "index_request" => "pages#index_request"
    get "index_ready" => "pages#index_ready"
    get "index_closed" => "pages#index_closed"
    get "index_wait_close" => "pages#index_wait_close"
    delete "index_:state" => "pages#destroy_all", state: /approve|request|ready|closed|wait_close/
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
