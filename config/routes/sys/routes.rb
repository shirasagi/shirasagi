# coding: utf-8
SS::Application.routes.draw do

  Sys::Initializer

  concern :deletion do
    get :delete, :on => :member
  end

  namespace "sys", path: ".sys" do
    get "/" => "main#index", as: :main
    get "info" => "info#index", as: :info
    get "test" => "test#index", as: :test
    resources :users, concerns: :deletion
    resources :groups, concerns: :deletion
    resources :sites, concerns: :deletion
    resources :roles, concerns: :deletion
    get "/search_groups" => "search_groups#index"
    post "/search_groups" => "search_groups#search"

    namespace "db" do
      get "/" => "main#index"
      resources :colls, concerns: :deletion
      resources :docs, concerns: :deletion, path: "colls/:coll/docs"
    end
  end

end
