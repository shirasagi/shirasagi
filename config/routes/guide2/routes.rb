Rails.application.routes.draw do

  Guide2::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :collection
  end

  concern :import do
    match :import, on: :collection, via: %i[get post]
  end

  content "guide2" do
    get "/" => redirect { |p, req| "#{req.path}/questions" }, as: :main
    resources :results, concerns: [:deletion, :download, :import]
    resources :questions, concerns: [:deletion, :download, :import]
    #match :table, on: :collection, via: %i[get post]
    get "qa_table" => "qa_table#index", as: :qa_table
    post "qa_table" => "qa_table#update"
    put "qa_table" => "qa_table#update"
  end

  node "guide2" do
    get "question/(index.:format)" => "public#index", cell: "nodes/question"
    get "question/results(.:format)" => "public#results", cell: "nodes/question"

    # get "guide/(index.:format)" => "public#index", cell: "nodes/guide"
    # get "guide/results(.:format)" => "public#results", cell: "nodes/guide"

    # get "guide(index.:format)" => "public#index", cell: "nodes/guide"
    # get "guide/dialog(.:format)" => "public#dialog", cell: "nodes/guide"
    # get "guide/result/" => "public#result", cell: "nodes/guide"
    # get "guide/result/:condition" => "public#result", cell: "nodes/guide"
    # get "guide/answer/" => "public#answer", cell: "nodes/guide"
    # get "guide/answer/:condition" => "public#answer", cell: "nodes/guide"
    # get "guide/procedure/" => "public#procedure", cell: "nodes/guide"
    # get "guide/procedure/:condition" => "public#procedure", cell: "nodes/guide"
  end
end
