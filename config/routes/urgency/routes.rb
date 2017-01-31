SS::Application.routes.draw do

  Urgency::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  content "urgency" do
    get "/" => redirect { |p, req| "#{req.path}/layouts" }, as: :main
    resources :layouts, only: [:index, :show, :update]
    resources :errors, only: :show
  end

  node "urgency" do
    get "layout/(index.html)" => "public#empty", cell: "nodes/layout"
    get "layout/layout-:layout.html" => "public#index", cell: "nodes/layout", layout: /\d+/
  end

  namespace "urgency", path: ".s:site/urgency" do
    namespace "apis" do
      get "layouts" => "layouts#index"
    end
  end
end
