SS::Application.routes.draw do

  Ads::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  content "ads" do
    get "/" => redirect { |p, req| "#{req.path}/banners" }, as: :main
    resources :banners, concerns: :deletion
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
