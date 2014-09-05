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
    resources :datasets, concerns: :deletion
    resources :apps, concerns: :deletion
    resources :ideas, concerns: :deletion
  end

  node "opendata" do
    get "dataset/(index.:format)" => "public#index", cell: "nodes/dataset"
    get "dataset/:id/(index.:format)" => "public#show", cell: "nodes/dataset"
    get "app/(index.:format)" => "public#index", cell: "nodes/app"
    get "app/:id/(index.:format)" => "public#show", cell: "nodes/app"
    get "idea/(index.:format)" => "public#index", cell: "nodes/idea"
    get "idea/:id/(index.:format)" => "public#show", cell: "nodes/idea"

    get "sparql/(*path)" => "public#index", cell: "nodes/sparql"
    get "api/*path" => "public#index", cell: "nodes/api"

    get "dataset/new.html" => "public#new", cell: "nodes/dataset"
    post "dataset/create.html" => "public#create", cell: "nodes/dataset"
    get "dataset/file.html" => "public#file", cell: "nodes/dataset"
    post "dataset/upload.html" => "public#upload", cell: "nodes/dataset"

    #get "dataset/:id/edit/(index.:format)" => "public#edit", cell: "nodes/dataset"
    #patch "dataset/:id/(index.:format)" => "public#update", cell: "nodes/dataset"
    #put "dataset/:id/(index.:format)" => "public#update", cell: "nodes/dataset"
    #delete "dataset/:id/(index.:format)" => "public#delete", cell: "nodes/dataset"

    get "mypage/(index.html)" => "public#index", cell: "nodes/mypage"
    get "mypage/login"  => "public#login", cell: "nodes/mypage"
    post "mypage/login" => "public#login", cell: "nodes/mypage"
    get "mypage/logout" => "public#logout", cell: "nodes/mypage"

    resource :profile, path: "my_profile", controller: "public", cell: "nodes/my_profile", concerns: :deletion
    resources :datasets, path: "my_dataset", controller: "public", cell: "nodes/my_dataset", concerns: :deletion

    get "user/(index.:format)" => "public#index", cell: "nodes/user"
    post "user/login.html" => "public#login", cell: "nodes/user"
    post "user/logout.html" => "public#logout", cell: "nodes/user"

    get "user/:user/dataset/(index.:format)" => "public#index", cell: "nodes/user_dataset"
    get "user/:user/dataset/:id/(index.:format)" => "public#show", cell: "nodes/user_dataset"
    get "user/:user/app/(index.:format)" => "public#index", cell: "nodes/user_app"
    get "user/:user/app/:id/(index.:format)" => "public#show", cell: "nodes/user_app"
    get "user/:user/idea/(index.:format)" => "public#index", cell: "nodes/user_idea"
    get "user/:user/idea/:id/(index.:format)" => "public#show", cell: "nodes/user_idea"

    get "user/:user/dataset/new/(index.:format)" => "public#new", cell: "nodes/user_dataset"
    post "user/:user/dataset/(index.:format)" => "public#create", cell: "nodes/user_dataset"
    get "user/:user/dataset/:id/edit/(index.:format)" => "public#edit", cell: "nodes/user_dataset"
    patch "user/:user/dataset/:id/(index.:format)" => "public#update", cell: "nodes/user_dataset"
    put "user/:user/dataset/:id/(index.:format)" => "public#update", cell: "nodes/user_dataset"
    delete "user/:user/dataset/:id/(index.:format)" => "public#delete", cell: "nodes/user_dataset"

  end

  part "opendata" do
    get "mypage"  => "public#index", cell: "parts/mypage"
    get "dataset" => "public#index", cell: "parts/dataset"
    get "app"     => "public#index", cell: "parts/app"
    get "idea"    => "public#index", cell: "parts/idea"
  end

#  page "opendata" do
#    get "page/:filename.:format" => "public#index", cell: "pages/page"
#  end

end
