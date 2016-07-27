SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    get "/" => "main#index", as: :main
    resources :licenses, concerns: :deletion
    resources :crawls, concerns: :deletion
    resources :dataset_categories, concerns: :deletion
    resources :dataset_groups, concerns: :deletion do
      get "search" => "dataset_groups/search#index", on: :collection
    end
    resources :datasets, concerns: :deletion do
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

    resources :ideas, concerns: :deletion do
      resources :comments, concerns: :deletion
    end

    resources :app_categories, concerns: :deletion

    resources :idea_categories, concerns: :deletion

    resources :search_datasets, concerns: :deletion
    resources :search_dataset_groups, concerns: :deletion
    resources :search_apps, concerns: :deletion
    resources :search_ideas, concerns: :deletion
    resources :sparqls, concerns: :deletion
    resources :apis, concerns: :deletion
    resources :mypages, concerns: :deletion
    resources :my_datasets, concerns: :deletion
    resources :my_apps, concerns: :deletion
    resources :my_ideas, concerns: :deletion
    resources :apps, concerns: :deletion do
      resources :appfiles, concerns: :deletion do
        get "file" => "appfiles#download"
      end
    end
    resources :members, only: [:index]
  end

  node "opendata" do
    get "category/" => "public#index", cell: "nodes/category"
    get "area/" => "public#index", cell: "nodes/area"

    get "dataset_category/" => "public#nothing", cell: "nodes/dataset_category"
    get "dataset_category/:name/" => "public#index", cell: "nodes/dataset_category"
    get "dataset_category/:name/rss.xml" => "public#rss", cell: "nodes/dataset_category"
    get "dataset_category/:name/areas" => "public#index_areas", cell: "nodes/dataset_category"
    get "dataset_category/:name/tags" => "public#index_tags", cell: "nodes/dataset_category"
    get "dataset_category/:name/formats" => "public#index_formats", cell: "nodes/dataset_category"
    get "dataset_category/:name/licenses" => "public#index_licenses", cell: "nodes/dataset_category"

    get "dataset/(index.:format)" => "public#index", cell: "nodes/dataset"
    get "dataset/rss.xml" => "public#rss", cell: "nodes/dataset"
    get "dataset/areas" => "public#index_areas", cell: "nodes/dataset"
    get "dataset/tags" => "public#index_tags", cell: "nodes/dataset"
    get "dataset/formats" => "public#index_formats", cell: "nodes/dataset"
    get "dataset/licenses" => "public#index_licenses", cell: "nodes/dataset"
    get "dataset/:dataset/resource/:id/" => "public#index", cell: "nodes/resource"
    get "dataset/:dataset/resource/:id/content.html" => "public#content", cell: "nodes/resource", format: false
    get "dataset/:dataset/resource/:id/*filename" => "public#download", cell: "nodes/resource", format: false
    get "dataset/:dataset/url_resource/:id/" => "public#index", cell: "nodes/url_resource"
    get "dataset/:dataset/url_resource/:id/content.html" => "public#content", cell: "nodes/url_resource", format: false
    get "dataset/:dataset/url_resource/:id/*filename" => "public#download", cell: "nodes/url_resource", format: false
    get "dataset/:dataset/point.:format" => "public#show_point", cell: "nodes/dataset", format: false
    post "dataset/:dataset/point.:format" => "public#add_point", cell: "nodes/dataset", format: false
    get "dataset/:dataset/point/members.html" => "public#point_members", cell: "nodes/dataset", format: false
    get "dataset/:dataset/apps/show.:format" => "public#show_apps", cell: "nodes/dataset", format: false
    get "dataset/:dataset/ideas/show.:format" => "public#show_ideas", cell: "nodes/dataset", format: false

    get "dataset/datasets/search(.:format)" => "public#datasets_search", cell: "nodes/dataset"
    post "dataset/datasets/search(.:format)" => "public#datasets_search", cell: "nodes/dataset"

    match "search_dataset_group/(index.:format)" => "public#index", cell: "nodes/search_dataset_group", via: [:get, :post]
    match "search_dataset/(index.:format)" => "public#index", cell: "nodes/search_dataset", via: [:get, :post]
    get "search_dataset/rss.xml" => "public#rss", cell: "nodes/search_dataset"

    get "app_category/" => "public#nothing", cell: "nodes/app_category"
    get "app_category/:name/" => "public#index", cell: "nodes/app_category"
    get "app_category/:name/rss.xml" => "public#rss", cell: "nodes/app_category"
    get "app_category/:name/areas" => "public#index_areas", cell: "nodes/app_category"
    get "app_category/:name/tags" => "public#index_tags", cell: "nodes/app_category"
    get "app_category/:name/licenses" => "public#index_licenses", cell: "nodes/app_category"

    get "app/(index.:format)" => "public#index", cell: "nodes/app"
    get "app/rss.xml" => "public#rss", cell: "nodes/app"
    get "app/areas" => "public#index_areas", cell: "nodes/app"
    get "app/tags" => "public#index_tags", cell: "nodes/app"
    get "app/licenses" => "public#index_licenses", cell: "nodes/app"
    get "app/:app/point.:format" => "public#show_point", cell: "nodes/app", format: false
    post "app/:app/point.:format" => "public#add_point", cell: "nodes/app", format: false
    get "app/:app/point/members.html" => "public#point_members", cell: "nodes/app", format: false
    get "app/:app/ideas/show.:format" => "public#show_ideas", cell: "nodes/app", format: false
    get "app/:app/executed/show.:format" => "public#show_executed", cell: "nodes/app", format: false
    match "app/:app/executed/add.:format" => "public#add_executed", cell: "nodes/app", via: [:get, :post]

    get "app/:app/zip" => "public#download", cell: "nodes/app", format: false
    get "app/:app/appfile/:id/" => "public#index", cell: "nodes/appfile"
    get "app/:app/appfile/:id/content.html" => "public#content", cell: "nodes/appfile", format: false
    get "app/:app/appfile/:id/json.html" => "public#json", cell: "nodes/appfile", format: false
    get "app/:app/appfile/:id/*filename" => "public#download", cell: "nodes/appfile", format: false

    get "app/:app/full" => "public#full", cell: "nodes/app", format: false
    get "app/:app/file_index/:file_id/*filename" => "public#app_index", cell: "nodes/app", format: false
    get "app/:app/file_text/:file_id/*filename" => "public#text", cell: "nodes/app", format: false

    match "search_app/(index.:format)" => "public#index", cell: "nodes/search_app", via: [:get, :post]
    get "search_app/rss.xml" => "public#rss", cell: "nodes/search_app"

    get "idea_category/" => "public#nothing", cell: "nodes/idea_category"
    get "idea_category/:name/" => "public#index", cell: "nodes/idea_category"
    get "idea_category/:name/rss.xml" => "public#rss", cell: "nodes/idea_category"
    get "idea_category/:name/areas" => "public#index_areas", cell: "nodes/idea_category"
    get "idea_category/:name/tags" => "public#index_tags", cell: "nodes/idea_category"

    get "idea/(index.:format)" => "public#index", cell: "nodes/idea"
    get "idea/rss.xml" => "public#rss", cell: "nodes/idea"
    get "idea/areas" => "public#index_areas", cell: "nodes/idea"
    get "idea/tags" => "public#index_tags", cell: "nodes/idea"
    get "idea/:idea/point.:format" => "public#show_point", cell: "nodes/idea", format: false
    post "idea/:idea/point.:format" => "public#add_point", cell: "nodes/idea", format: false
    get "idea/:idea/point/members.html" => "public#point_members", cell: "nodes/idea", format: false
    get "idea/:idea/comment/show.:format" => "public#index", cell: "nodes/comment", format: false
    match "idea/:idea/comment/add.:format" => "public#add", cell: "nodes/comment", via: [:get, :post]
    match "idea/:idea/comment/delete.:format" => "public#delete", cell: "nodes/comment", via: [:get, :post]
    get "idea/:idea/dataset/show.:format" => "public#show_dataset", cell: "nodes/idea", format: false
    get "idea/:idea/app/show.:format" => "public#show_app", cell: "nodes/idea", format: false

    match "search_idea/(index.:format)" => "public#index", cell: "nodes/search_idea", via: [:get, :post]
    get "search_idea/rss.xml" => "public#rss", cell: "nodes/search_idea"

    get "sparql/(*path)" => "public#index", cell: "nodes/sparql"
    post "sparql/(*path)" => "public#index", cell: "nodes/sparql"
    get "api/package_list" => "public#package_list", cell: "nodes/api"
    get "api/group_list" => "public#group_list", cell: "nodes/api"
    get "api/tag_list" => "public#tag_list", cell: "nodes/api"
    get "api/package_show" => "public#package_show", cell: "nodes/api"
    get "api/tag_show" => "public#tag_show", cell: "nodes/api"
    get "api/group_show" => "public#group_show", cell: "nodes/api"
    get "api/1/package_list" => "public#package_list", cell: "nodes/api"
    get "api/1/group_list" => "public#group_list", cell: "nodes/api"
    get "api/1/tag_list" => "public#tag_list", cell: "nodes/api"
    get "api/1/package_show" => "public#package_show", cell: "nodes/api"
    get "api/1/tag_show" => "public#tag_show", cell: "nodes/api"
    get "api/1/group_show" => "public#group_show", cell: "nodes/api"

    get "member/" => "public#index", cell: "nodes/member"
    get "member/:member" => "public#show", cell: "nodes/member"
    get "member/:member/datasets/(:filename.:format)" => "public#datasets", cell: "nodes/member"
    get "member/:member/apps/(:filename.:format)" => "public#apps", cell: "nodes/member"
    get "member/:member/ideas/(:filename.:format)" => "public#ideas", cell: "nodes/member"

    get "mypage/(index.html)" => "public#index", cell: "nodes/mypage"
    get "mypage/login"  => "public#login", cell: "nodes/mypage"
    post "mypage/login" => "public#login", cell: "nodes/mypage"
    get "mypage/logout" => "public#logout", cell: "nodes/mypage"
    get "mypage/notice/show.:format" => "public#show_notice", cell: "nodes/mypage", format: false
    get "mypage/notice/confirm.:format" => "public#confirm_notice", cell: "nodes/mypage", format: false
    get "mypage/:provider" => "public#provide", cell: "nodes/mypage"

    resource :profile, path: "my_profile", controller: "public", cell: "nodes/my_profile", concerns: :deletion
    resources :datasets, path: "my_dataset", controller: "public", cell: "nodes/my_dataset", concerns: :deletion do
      resources :resources, controller: "public", cell: "nodes/my_dataset/resources", concerns: :deletion do
        get "file" => "public#download"
        get "tsv" => "public#download_tsv"
      end
    end
    resources :apps, path: "my_app", controller: "public", cell: "nodes/my_app", concerns: :deletion do
      resources :appfiles, controller: "public", cell: "nodes/my_app/appfiles", concerns: :deletion do
        get "file" => "public#download"
      end
    end
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
    get "app/:filename.:format" => "public#index", cell: "pages/app"
    get "idea/:filename.:format" => "public#index", cell: "pages/idea"
  end
end
