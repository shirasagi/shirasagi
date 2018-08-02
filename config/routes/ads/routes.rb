SS::Application.routes.draw do

  Ads::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :trash do
    get :trash, on: :collection
    delete :trash, action: :destroy_all, on: :collection
    match :soft_delete, on: :member, via: [:get, :post]
    match :undo_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :command do
    get :command, on: :member
    post :command, on: :member
  end

  content "ads" do
    get "/" => redirect { |p, req| "#{req.path}/banners" }, as: :main
    resources :banners, concerns: [:deletion, :trash, :command]
    get "access_logs" => "access_logs#index", as: :access_logs
    get "access_logs/download" => "access_logs#download", as: :access_logs_download
  end

  node "ads" do
    get "banner/" => "public#index", cell: "nodes/banner"
    get "banner/:filename.:format.count" => "public#count", cell: "nodes/banner"
  end

  part "ads" do
    get "banner" => "public#index", cell: "parts/banner"
  end

  page "ads" do
    get "banner/:filename.:format" => "public#index", cell: "pages/banner"
  end

end
