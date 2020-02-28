Rails.application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :copy do
    get :copy, on: :member
    put :copy, on: :member
  end

  concern :command do
    get :command, on: :member
    post :command, on: :member
  end

  content "opendata" do
    get "dataset_public_entity" => "dataset/public_entity#index", as: :dataset_public_entity
    get "dataset_public_entity_download" => "dataset/public_entity#download", as: :dataset_public_entity_download
    resources :crawls, concerns: :deletion, module: :dataset
    resources :dataset_categories, concerns: :deletion, module: :dataset
    resources :dataset_estat_categories, concerns: :deletion, module: :dataset
    resources :dataset_areas, concerns: :deletion, module: :dataset
    resources :dataset_groups, concerns: :deletion, module: :dataset do
      get "search" => "dataset_groups/search#index", on: :collection
    end
    get 'export_datasets' => 'dataset/export_datasets#index'
    put 'export_datasets' => 'dataset/export_datasets#export'
    get 'start_export_datasets' => 'dataset/export_datasets#start_export'
    get 'import_datasets' => 'dataset/import_datasets#index'
    put 'import_datasets' => 'dataset/import_datasets#import'
    resources :datasets, concerns: [:deletion, :copy, :command], module: :dataset do

      get "search" => "datasets/search#index", on: :collection
      get :check_for_update, on: :member
      resources :resources, concerns: :deletion do
        get "file" => "resources#download"
        get "tsv" => "resources#download_tsv"
        get "content" => "resources#content"
        get "guidance" => "csv2rdf_settings#guidance"
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
        get :check_for_update, on: :member
        match :sync, on: :member, via: [ :get, :post ]
      end

      resources :url_resources, concerns: :deletion do
        get "file" => "url_resources#download"
        get "content" => "url_resources#content"
      end
      get :public_entity_download, on: :collection
    end
    resources :search_datasets, concerns: :deletion, module: :dataset
    resources :search_dataset_groups, concerns: :deletion, module: :dataset
    resources :dataset_maps, concerns: :deletion, module: :dataset

    scope "report", as: "dataset_report" do
      get "/" => redirect { |p, req| "#{req.path}/downloads" }, as: :main
      resources :downloads, only: %i[index], controller: "dataset/resource_download_reports" do
        get :download, on: :collection
      end
      resources :accesses, only: %i[index], controller: "dataset/access_reports" do
        get :download, on: :collection
      end
      resources :previews, only: %i[index], controller: "dataset/resource_preview_reports" do
        get :download, on: :collection
      end
    end
    scope "history", as: "dataset_history" do
      get "/" => redirect { |p, req| "#{req.path}/downloads/#{Time.zone.now.strftime('%Y%m%d')}" }, as: :main
      get "/downloads" => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m%d')}" }, as: :downloads_main
      resources :downloads, only: %i[index], controller: "dataset/resource_download_histories", path: 'downloads/:ymd' do
        get :download, on: :collection
      end
      resources :download_archives, only: %i[index show destroy], concerns: :deletion,
                controller: "dataset/resource_download_history_archives"
      get "/previews" => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m%d')}" }, as: :previews_main
      resources :previews, only: %i[index], controller: "dataset/resource_preview_histories", path: 'previews/:ymd' do
        get :download, on: :collection
      end
      resources :preview_archives, only: %i[index show destroy], concerns: :deletion,
                controller: "dataset/resource_preview_history_archives"
    end

    scope module: :dataset do
      namespace :harvest do
        resources :importers, concerns: :deletion do
          get :import, on: :member
          put :import, on: :member
          get :destroy_datasets, on: :member
          put :destroy_datasets, on: :member
          scope module: :importer do
            resources :category_settings, concerns: :deletion, path: 'c:category_id', defaults: { category_id: '-' } do
              get :download, on: :collection
              get :import, on: :collection
              put :import, on: :collection
            end
            resources :estat_category_settings, concerns: :deletion, path: 'estat:category_id', defaults: { category_id: '-' } do
              get :download, on: :collection
              get :import, on: :collection
              put :import, on: :collection
            end
            resources :reports, only: [:show, :destroy], concerns: :deletion do
              get :dataset, on: :member
              get :download, on: :member
            end
          end
        end
        resources :exporters, concerns: :deletion do
          get :export, on: :member
          put :export, on: :member
          scope module: :exporter do
            resources :group_settings, concerns: :deletion
            resources :owner_org_settings, concerns: :deletion
          end
        end
      end
    end
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

    get "dataset_estat_category/" => "public#index", cell: "nodes/dataset/dataset_estat_category"
    get "dataset_estat_category/rss.xml" => "public#rss", cell: "nodes/dataset/dataset_estat_category"
    get "dataset_estat_category/:name/" => "public#index", cell: "nodes/dataset/dataset_estat_category"
    get "dataset_estat_category/:name/rss.xml" => "public#rss", cell: "nodes/dataset/dataset_estat_category"

    get "dataset_area/" => "public#index", cell: "nodes/dataset/dataset_area"
    get "dataset_area/rss.xml" => "public#rss", cell: "nodes/dataset/dataset_area"
    get "dataset_area/*name/rss.xml" => "public#rss", cell: "nodes/dataset/dataset_area", name: /[^\.]+/
    get "dataset_area/*name/" => "public#index", cell: "nodes/dataset/dataset_area", name: /[^\.]+/
    get "dataset_map/" => "public#index", cell: "nodes/dataset/dataset_map"
    get "dataset_map/search.html" => "public#search", cell: "nodes/dataset/dataset_map"

    get "dataset/(index.:format)" => "public#index", cell: "nodes/dataset/dataset"
    get "dataset/rss.xml" => "public#rss", cell: "nodes/dataset/dataset"
    get "dataset/categories" => "public#index_categories", cell: "nodes/dataset/dataset"
    get "dataset/estat_categories" => "public#index_estat_categories", cell: "nodes/dataset/dataset"
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
    get "dataset/:dataset/url_resource/:id/download" => "public#download", cell: "nodes/dataset/url_resource", format: false
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
    get "search_dataset/tags" => "public#index_tags", cell: "nodes/dataset/search_dataset"
    get "search_dataset/search" => "public#search", cell: "nodes/dataset/search_dataset"
    get "search_dataset/rss.xml" => "public#rss", cell: "nodes/dataset/search_dataset"
    match "search_dataset/bulk_download" => "public#bulk_download", cell: "nodes/dataset/search_dataset", via: [:get, :post]
    match "search_dataset/dataset_download/:id" => "public#dataset_download", cell: "nodes/dataset/search_dataset",
          via: [:get, :post]
  end

  part "opendata" do
    get "dataset" => "public#index", cell: "parts/dataset/dataset"
    get "dataset_group" => "public#index", cell: "parts/dataset/dataset_group"
    get "dataset_counter" => "public#index", cell: "parts/dataset/dataset_counter"
  end

  page "opendata" do
    get "dataset/:filename.:format" => "public#index", cell: "pages/dataset/dataset"
  end
end
