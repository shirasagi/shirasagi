Rails.application.routes.draw do
  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  gws "bookmark" do
    get '/' => "main#index", as: :main

    namespace "apis" do
      post "item" => "items#update", as: "update_item"
      delete "item" => "items#destroy", as: "destroy_item"
      get "folders" => "folders#index", as: "folders"
      get "folder_list" => "folder_list#index"
    end

    scope(path: ':folder_id', defaults: { folder_id: '-' }) do
      resources :items, concerns: [:deletion]
    end
    resources :folders, concerns: [:deletion] do
      match :move, on: :member, via: [:get, :post]
    end
  end
end
