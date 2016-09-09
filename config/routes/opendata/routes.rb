SS::Application.routes.draw do

  Opendata::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :workflow do
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
    get :approver_setting, on: :member
    post :approver_setting, on: :member
    get :wizard, on: :member
    post :wizard, on: :member
  end

  content "opendata" do
    get "/" => "main#index", as: :main
    resources :licenses, concerns: :deletion

    resources :sparqls, concerns: :deletion
    resources :apis, concerns: :deletion
    resources :members, only: [:index]

    namespace "workflow" do
      resources :idea_comments, concerns: :workflow
    end
  end

  node "opendata" do
    get "category/" => "public#index", cell: "nodes/category"
    get "area/" => "public#index", cell: "nodes/area"

    get "sparql/(*path)" => "public#index", cell: "nodes/sparql"
    post "sparql/(*path)" => "public#index", cell: "nodes/sparql"
    get "api/package_list" => "public#package_list", cell: "nodes/api"
    get "api/group_list" => "public#group_list", cell: "nodes/api"
    get "api/tag_list" => "public#tag_list", cell: "nodes/api"
    get "api/package_show" => "public#package_show", cell: "nodes/api"
    get "api/tag_show" => "public#tag_show", cell: "nodes/api"
    get "api/group_show" => "public#group_show", cell: "nodes/api"
    get "api/package_search" => "public#package_search", cell: "nodes/api"
    get "api/resource_search" => "public#resource_search", cell: "nodes/api"
    get "api/1/package_list" => "public#package_list", cell: "nodes/api"
    get "api/1/group_list" => "public#group_list", cell: "nodes/api"
    get "api/1/tag_list" => "public#tag_list", cell: "nodes/api"
    get "api/1/package_show" => "public#package_show", cell: "nodes/api"
    get "api/1/tag_show" => "public#tag_show", cell: "nodes/api"
    get "api/1/group_show" => "public#group_show", cell: "nodes/api"
    get "api/1/package_search" => "public#package_search", cell: "nodes/api"
    get "api/1/resource_search" => "public#resource_search", cell: "nodes/api"

    # get "member/" => "public#index", cell: "nodes/member"
    get "member/:member" => "public#show", cell: "nodes/member"
    get "member/:member/datasets/(:filename.:format)" => "public#datasets", cell: "nodes/member"
    get "member/:member/apps/(:filename.:format)" => "public#apps", cell: "nodes/member"
    get "member/:member/ideas/(:filename.:format)" => "public#ideas", cell: "nodes/member"
  end
end
