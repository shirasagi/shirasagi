SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    resources :app_categories, concerns: :deletion
    resources :search_apps, concerns: :deletion
    resources :apps, concerns: :deletion do
      resources :appfiles, concerns: :deletion do
        get "file" => "appfiles#download"
      end
    end
  end

  node "opendata" do
    get "app_category/" => "public#nothing", cell: "nodes/app/app_category"
    get "app_category/:name/" => "public#index", cell: "nodes/app/app_category"
    get "app_category/:name/rss.xml" => "public#rss", cell: "nodes/app/app_category"
    get "app_category/:name/areas" => "public#index_areas", cell: "nodes/app/app_category"
    get "app_category/:name/tags" => "public#index_tags", cell: "nodes/app/app_category"
    get "app_category/:name/licenses" => "public#index_licenses", cell: "nodes/app/app_category"

    get "app/(index.:format)" => "public#index", cell: "nodes/app/app"
    get "app/rss.xml" => "public#rss", cell: "nodes/app/app"
    get "app/areas" => "public#index_areas", cell: "nodes/app/app"
    get "app/tags" => "public#index_tags", cell: "nodes/app/app"
    get "app/licenses" => "public#index_licenses", cell: "nodes/app/app"
    get "app/:app/point.:format" => "public#show_point", cell: "nodes/app/app", format: false
    post "app/:app/point.:format" => "public#add_point", cell: "nodes/app/app", format: false
    get "app/:app/point/members.html" => "public#point_members", cell: "nodes/app/app", format: false
    get "app/:app/ideas/show.:format" => "public#show_ideas", cell: "nodes/app/app", format: false
    get "app/:app/executed/show.:format" => "public#show_executed", cell: "nodes/app/app", format: false
    post "app/:app/executed/add.:format" => "public#add_executed", cell: "nodes/app/app", format: false

    get "app/:app/zip" => "public#download", cell: "nodes/app/app", format: false
    get "app/:app/appfile/:id/" => "public#index", cell: "nodes/app/appfile"
    get "app/:app/appfile/:id/content.html" => "public#content", cell: "nodes/app/appfile", format: false
    get "app/:app/appfile/:id/json.html" => "public#json", cell: "nodes/app/appfile", format: false
    get "app/:app/appfile/:id/*filename" => "public#download", cell: "nodes/app/appfile", format: false

    get "app/:app/full" => "public#full", cell: "nodes/app/app", format: false
    get "app/:app/file_index/(*filename)" => "public#app_index", cell: "nodes/app/app", format: false
    get "app/:app/file_text/(*filename)" => "public#text", cell: "nodes/app/app", format: false

    match "search_app/(index.:format)" => "public#index", cell: "nodes/app/search_app", via: [:get, :post]
    get "search_app/rss.xml" => "public#rss", cell: "nodes/app/search_app"
  end

  part "opendata" do
    get "app" => "public#index", cell: "parts/app/app"
  end

  page "opendata" do
    get "app/:filename.:format" => "public#index", cell: "pages/app/app"
  end
end
