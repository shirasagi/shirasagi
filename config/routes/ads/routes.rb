SS::Application.routes.draw do

  Ads::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "ads" do
    get "/" => redirect { |p, req| "#{req.path}/banners" }, as: :main
    resources :banners, concerns: :deletion
    get "access_logs" => "access_logs#index", as: :access_logs
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
