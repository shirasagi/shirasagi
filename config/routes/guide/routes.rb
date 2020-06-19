Rails.application.routes.draw do

  Guide::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  namespace "guide", path: ".s:site/guide" do
    namespace "apis" do
      scope ":nid/:id" do
        get "questions" => "questions#index"
        get "procedures" => "procedures#index"
      end
    end
  end

  content "guide" do
    get "/" => redirect { |p, req| "#{req.path}/questions" }, as: :main
    resources :guides, only: [:index]
    resources :questions, concerns: :deletion
    resources :procedures, concerns: :deletion
    resources :diagram, only: [:index]
  end

  node "guide" do
    get "guide(index.:format)" => "public#index", cell: "nodes/guide"
    get "guide/dialog(.:format)" => "public#dialog", cell: "nodes/guide"

    get "guide/result/" => "public#result", cell: "nodes/guide"
    get "guide/result/:condition" => "public#result", cell: "nodes/guide"
    get "guide/answer/" => "public#answer", cell: "nodes/guide"
    get "guide/answer/:condition" => "public#answer", cell: "nodes/guide"
    get "guide/procedure/" => "public#procedure", cell: "nodes/guide"
    get "guide/procedure/:condition" => "public#procedure", cell: "nodes/guide"
  end
end
