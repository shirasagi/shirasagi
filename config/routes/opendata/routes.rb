# coding: utf-8
SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

#  namespace "opendata", path: ".opendata" do
#    get "/" => "main#index", as: :main
#
#    resources :datasets, concerns: :deletion
#    resources :apps, concerns: :deletion
#    resources :ideas, concerns: :deletion
#  end

  content "opendata" do
    get "/" => "main#index", as: :main
    resources :data_groups, concerns: :deletion
    resources :datasets, concerns: :deletion do
      resources :resources, concerns: :deletion
    end
    resources :apps, concerns: :deletion
    resources :ideas, concerns: :deletion
  end

  node "opendata" do
    get "dataset/(index.:format)" => "public#index", cell: "nodes/dataset"
    get "dataset/:id.:format" => "public#show", cell: "nodes/dataset"

    get "app/(index.:format)" => "public#index", cell: "nodes/app"
    get "app/:id/(index.:format)" => "public#show", cell: "nodes/app"
    get "idea/(index.:format)" => "public#index", cell: "nodes/idea"
    get "idea/:id/(index.:format)" => "public#show", cell: "nodes/idea"

    get "sparql/(*path)" => "public#index", cell: "nodes/sparql"
    get "api/*path" => "public#index", cell: "nodes/api"

    get "mypage/(index.html)" => "public#index", cell: "nodes/mypage"
    get "mypage/login"  => "public#login", cell: "nodes/mypage"
    post "mypage/login" => "public#login", cell: "nodes/mypage"
    get "mypage/logout" => "public#logout", cell: "nodes/mypage"

    resource :profile, path: "my_profile", controller: "public", cell: "nodes/my_profile", concerns: :deletion
    resources :datasets, path: "my_dataset", controller: "public", cell: "nodes/my_dataset", concerns: :deletion
  end

  part "opendata" do
    get "mypage_login" => "public#index", cell: "parts/mypage_login"
    get "dataset" => "public#index", cell: "parts/dataset"
    get "app" => "public#index", cell: "parts/app"
    get "idea" => "public#index", cell: "parts/idea"
  end

#  page "opendata" do
#    get "page/:filename.:format" => "public#index", cell: "pages/page"
#  end

end
