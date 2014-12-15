SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    get "/" => "main#index", as: :main
    resources :licenses, concerns: :deletion
    resources :dataset_categories, concerns: :deletion
    resources :dataset_groups, concerns: :deletion do
      get "search" => "dataset_groups/search#index", on: :collection
    end
    resources :datasets, concerns: :deletion do
      resources :resources, concerns: :deletion do
        get "file" => "resources#download"
        get "tsv" => "resources#download_tsv"
        get "content" => "resources#content"
      end
    end
    resources :search_datasets, concerns: :deletion
    resources :search_dataset_groups, concerns: :deletion
    resources :sparqls, concerns: :deletion
    resources :apis, concerns: :deletion
    resources :mypages, concerns: :deletion
    resources :my_datasets, concerns: :deletion
    resources :apps, concerns: :deletion
    resources :ideas, concerns: :deletion
  end

  node "opendata" do
    get "category/" => "public#index", cell: "nodes/category"
    get "area/" => "public#index", cell: "nodes/area"

    get "dataset_category/" => "public#nothing", cell: "nodes/dataset_category"
    get "dataset_category/:name/" => "public#index", cell: "nodes/dataset_category"
    get "dataset/(index.:format)" => "public#index", cell: "nodes/dataset"
    get "dataset/:dataset/resource/:id/" => "public#index", cell: "nodes/resource"
    get "dataset/:dataset/resource/:id/content.html" => "public#content", cell: "nodes/resource", format: false
    get "dataset/:dataset/resource/:id/*filename" => "public#download", cell: "nodes/resource", format: false
    get "dataset/:dataset/point/show.:format" => "public#show_point", cell: "nodes/dataset", format: false
    get "dataset/:dataset/point/add.:format" => "public#add_point", cell: "nodes/dataset", format: false
    get "dataset/:dataset/point/members.html" => "public#point_members", cell: "nodes/dataset", format: false

    match "search_dataset_group/(index.:format)" => "public#index", cell: "nodes/search_dataset_group", via: [:get, :post]
    match "search_dataset/(index.:format)" => "public#index", cell: "nodes/search_dataset", via: [:get, :post]

    get "app/(index.:format)" => "public#index", cell: "nodes/app"
    get "app/:id/(index.:format)" => "public#show", cell: "nodes/app"
    get "idea/(index.:format)" => "public#index", cell: "nodes/idea"
    get "idea/:id/(index.:format)" => "public#show", cell: "nodes/idea"

    get "sparql/(*path)" => "public#index", cell: "nodes/sparql"
    post "sparql/(*path)" => "public#index", cell: "nodes/sparql"
    get "api/package_list" => "public#package_list", cell: "nodes/api"
    get "api/group_list" => "public#group_list", cell: "nodes/api"
    get "api/tag_list" => "public#tag_list", cell: "nodes/api"
    get "api/(*path)" => "public#index", cell: "nodes/api"

    get "member/:member" => "public#index", cell: "nodes/member"

    get "mypage/(index.html)" => "public#index", cell: "nodes/mypage"
    get "mypage/login"  => "public#login", cell: "nodes/mypage"
    post "mypage/login" => "public#login", cell: "nodes/mypage"
    get "mypage/logout" => "public#logout", cell: "nodes/mypage"
    get "mypage/:provider" => "public#provide", cell: "nodes/mypage"

    resource :profile, path: "my_profile", controller: "public", cell: "nodes/my_profile", concerns: :deletion
    resources :datasets, path: "my_dataset", controller: "public", cell: "nodes/my_dataset", concerns: :deletion do
      resources :resources, controller: "public", cell: "nodes/my_dataset/resources", concerns: :deletion do
        get "file" => "public#download"
        get "tsv" => "public#download_tsv"
      end
    end
    resources :apps, path: "my_app", controller: "public", cell: "nodes/my_app", concerns: :deletion
    resources :ideas, path: "my_idea", controller: "public", cell: "nodes/my_idea", concerns: :deletion
  end

  part "opendata" do
    get "mypage_login" => "public#index", cell: "parts/mypage_login"
    get "dataset" => "public#index", cell: "parts/dataset"
    get "dataset_group" => "public#index", cell: "parts/dataset_group"

    get "app" => "public#index", cell: "parts/app"
    get "idea" => "public#index", cell: "parts/idea"
  end

  page "opendata" do
    get "dataset/:filename.:format" => "public#index", cell: "pages/dataset"
  end
end
