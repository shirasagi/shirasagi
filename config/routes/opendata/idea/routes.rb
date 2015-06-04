SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "opendata" do
    resources :ideas, concerns: :deletion do
      resources :comments, concerns: :deletion
    end

    resources :idea_categories, concerns: :deletion

    resources :search_ideas, concerns: :deletion
  end

  node "opendata" do
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
    post "idea/:idea/comment/add.:format" => "public#add", cell: "nodes/comment", format: false
    post "idea/:idea/comment/delete.:format" => "public#delete", cell: "nodes/comment", format: false
    get "idea/:idea/dataset/show.:format" => "public#show_dataset", cell: "nodes/idea", format: false
    get "idea/:idea/app/show.:format" => "public#show_app", cell: "nodes/idea", format: false

    match "search_idea/(index.:format)" => "public#index", cell: "nodes/search_idea", via: [:get, :post]
    get "search_idea/rss.xml" => "public#rss", cell: "nodes/search_idea"
  end

  part "opendata" do
    get "idea" => "public#index", cell: "parts/idea"
  end

  page "opendata" do
    get "idea/:filename.:format" => "public#index", cell: "pages/idea"
  end
end
