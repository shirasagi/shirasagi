Rails.application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :deletion_all do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  content "opendata" do
    get "datasets_approve" => "dataset/datasets#index_approve"
    get "datasets_request" => "dataset/datasets#index_request"
    get "datasets_closed" => "dataset/datasets#index_closed"
    delete "datasets_:state" => "dataset/datasets#destroy_all", state: /approve|request|closed/
    resources :my_datasets, concerns: :deletion_all, module: "mypage/dataset"
    resources :my_favorite_datasets, concerns: :deletion_all, module: "mypage/dataset"
  end

  node "opendata" do
    resources :datasets, path: "my_dataset", controller: "public",
              cell: "nodes/mypage/dataset/my_dataset", concerns: :deletion do
      resources :resources, controller: "public", cell: "nodes/mypage/dataset/my_dataset/resources", concerns: :deletion do
        get "file" => "public#download"
        get "tsv" => "public#download_tsv"
      end
    end
    resources :favorite_datasets, path: "my_favorite_dataset", controller: "public",
              cell: "nodes/mypage/dataset/my_favorite_dataset", only: [:index] do
      post :remove, on: :member
    end
  end
end
