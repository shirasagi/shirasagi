SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  content "opendata" do
    resources :crawls, concerns: :deletion, module: :dataset
    resources :dataset_categories, concerns: :deletion, module: :dataset
    resources :dataset_groups, concerns: :deletion, module: :dataset do
      get "search" => "dataset_groups/search#index", on: :collection
    end
    resources :datasets, concerns: :deletion, module: :dataset do
      get "search" => "datasets/search#index", on: :collection
      resources :resources, concerns: :deletion do
        get "file" => "resources#download"
        get "tsv" => "resources#download_tsv"
        get "content" => "resources#content"
        get "header_size" => "csv2rdf_settings#header_size"
        post "header_size" => "csv2rdf_settings#header_size"
        get "rdf_class" => "csv2rdf_settings#rdf_class"
        post "rdf_class" => "csv2rdf_settings#rdf_class"
        get "column_types" => "csv2rdf_settings#column_types"
        post "column_types" => "csv2rdf_settings#column_types"
        get "confirmation" => "csv2rdf_settings#confirmation"
        post "confirmation" => "csv2rdf_settings#confirmation"
        get "rdf_class_preview" => "csv2rdf_settings#rdf_class_preview"
        get "rdf_prop_select/:column_index" => "csv2rdf_settings#rdf_prop_select"
        post "rdf_prop_select/:column_index" => "csv2rdf_settings#rdf_prop_select"
      end

      resources :url_resources, concerns: :deletion do
        get "file" => "url_resources#download"
        get "content" => "url_resources#content"
      end

    end
    resources :search_datasets, concerns: :deletion, module: :dataset
    resources :search_dataset_groups, concerns: :deletion, module: :dataset
  end

  node "opendata" do
    get "dataset_category/" => "public#index", cell: "nodes/dataset/dataset_category"
    get "dataset_category/rss.xml" => "public#rss", cell: "nodes/dataset/dataset_category"
    get "dataset_category/:name/" => "public#index", cell: "nodes/dataset/dataset_category"
    get "dataset_category/:name/rss.xml" => "public#rss", cell: "nodes/dataset/dataset_category"
    # get "dataset_category/:name/areas" => "public#index_areas", cell: "nodes/dataset/dataset_category"
    # get "dataset_category/:name/tags" => "public#index_tags", cell: "nodes/dataset/dataset_category"
    # get "dataset_category/:name/formats" => "public#index_formats", cell: "nodes/dataset/dataset_category"
    # get "dataset_category/:name/licenses" => "public#index_licenses", cell: "nodes/dataset/dataset_category"

    get "dataset/(index.:format)" => "public#index", cell: "nodes/dataset/dataset"
    get "dataset/rss.xml" => "public#rss", cell: "nodes/dataset/dataset"
    get "dataset/areas" => "public#index_areas", cell: "nodes/dataset/dataset"
    get "dataset/tags" => "public#index_tags", cell: "nodes/dataset/dataset"
    get "dataset/formats" => "public#index_formats", cell: "nodes/dataset/dataset"
    get "dataset/licenses" => "public#index_licenses", cell: "nodes/dataset/dataset"
    get "dataset/:dataset/resource/:id/" => "public#index", cell: "nodes/dataset/resource"
    get "dataset/:dataset/resource/:id/content.html" => "public#content", cell: "nodes/dataset/resource", format: false
    get "dataset/:dataset/resource/:id/*filename" => "public#download", filename: /.*/,
      cell: "nodes/dataset/resource", format: false
    get "dataset/:dataset/url_resource/:id/" => "public#index", cell: "nodes/dataset/url_resource"
    get "dataset/:dataset/url_resource/:id/content.html" => "public#content", cell: "nodes/dataset/url_resource", format: false
    get "dataset/:dataset/url_resource/:id/*filename" => "public#download", filename: /.*/,
      cell: "nodes/dataset/url_resource", format: false
    get "dataset/:dataset/point.:format" => "public#show_point", cell: "nodes/dataset/dataset", format: false
    post "dataset/:dataset/point.:format" => "public#add_point", cell: "nodes/dataset/dataset", format: false
    get "dataset/:dataset/point/members.html" => "public#point_members", cell: "nodes/dataset/dataset", format: false
    get "dataset/:dataset/apps/show.:format" => "public#show_apps", cell: "nodes/dataset/dataset", format: false
    get "dataset/:dataset/ideas/show.:format" => "public#show_ideas", cell: "nodes/dataset/dataset", format: false

    get "dataset/datasets/search(.:format)" => "public#datasets_search", cell: "nodes/dataset/dataset"

    match "search_dataset_group/(index.:format)" => "public#index", cell: "nodes/dataset/search_dataset_group",
      via: [:get, :post]
    match "search_dataset/(index.:format)" => "public#index", cell: "nodes/dataset/search_dataset", via: [:get, :post]
    get "search_dataset/rss.xml" => "public#rss", cell: "nodes/dataset/search_dataset"
  end

  part "opendata" do
    get "dataset" => "public#index", cell: "parts/dataset/dataset"
    get "dataset_group" => "public#index", cell: "parts/dataset/dataset_group"
  end

  page "opendata" do
    get "dataset/:filename.:format" => "public#index", cell: "pages/dataset/dataset"
  end
end
