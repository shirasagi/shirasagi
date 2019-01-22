SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :deletion_all do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  content "opendata" do
    match "datasets_approve" => "dataset/datasets#index_approve", via: [:get, :delete]
    match "datasets_request" => "dataset/datasets#index_request", via: [:get, :delete]
    match "datasets_closed" => "dataset/datasets#index_closed", via: [:get, :delete]
    resources :my_datasets, concerns: :deletion_all, module: "mypage/dataset"
  end

  node "opendata" do
    resources :datasets, path: "my_dataset", controller: "public",
              cell: "nodes/mypage/dataset/my_dataset", concerns: :deletion do
      resources :resources, controller: "public", cell: "nodes/mypage/dataset/my_dataset/resources", concerns: :deletion do
        get "file" => "public#download"
        get "tsv" => "public#download_tsv"
      end
    end
  end
end
