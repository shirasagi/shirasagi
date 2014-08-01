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
    get "sparql/*path" => "public#index", cell: "nodes/sparql"
    get "api/*path" => "public#index", cell: "nodes/api"
    
    get "user/(index.:format)" => "public#index", cell: "nodes/user"
    get "user/:user/dataset/(index.:format)" => "public#index", cell: "nodes/user_dataset"
    get "user/:user/dataset/:id/(index.:format)" => "public#show", cell: "nodes/user_dataset"
    get "user/:user/app/(index.:format)" => "public#index", cell: "nodes/user_app"
    get "user/:user/app/:id/(index.:format)" => "public#show", cell: "nodes/user_app"
    get "user/:user/idea/(index.:format)" => "public#index", cell: "nodes/user_idea"
    get "user/:user/idea/:id/(index.:format)" => "public#show", cell: "nodes/user_idea"
  end
  
#  part "opendata" do
#    get "page" => "public#index", cell: "parts/page"
#  end
  
#  page "opendata" do
#    get "page/:filename.:format" => "public#index", cell: "pages/page"
#  end
  
end
