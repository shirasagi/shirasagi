SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    resources :my_datasets, concerns: :deletion, module: "mypage/dataset"
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
