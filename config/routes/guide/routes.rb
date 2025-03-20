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
    get "/" => redirect { |p, req| "#{req.path}/procedures" }, as: :main
    resources :guides, only: [:index]
    resources :questions, concerns: :deletion
    resources :procedures, concerns: :deletion
    resources :importers, only: [:index] do
      get :download_procedures, on: :collection
      get :import_procedures, on: :collection
      post :import_procedures, on: :collection

      get :download_questions, on: :collection
      get :import_questions, on: :collection
      post :import_questions, on: :collection

      get :download_transitions, on: :collection
      get :import_transitions, on: :collection
      post :import_transitions, on: :collection

      get :download_combinations, on: :collection
      get :import_combinations, on: :collection
      post :import_combinations, on: :collection

      get :download_template, on: :collection
    end
    resource :diagnostic, only: %i[show]
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
