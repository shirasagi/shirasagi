Rails.application.routes.draw do

  Guidance::Initializer

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

  content "guidance" do
    get "/" => redirect { |p, req| "#{req.path}/results" }, as: :main
    resources :guides, only: [:index]
    resources :results, concerns: :deletion, concerns: [:deletion, :download, :import]
    resource :questions, concerns: :deletion, concerns: [:download, :import]
  end

  node "guidance" do
    get "guide/(index.:format)" => "public#index", cell: "nodes/guide"
    get "guide/results(.:format)" => "public#results", cell: "nodes/guide"
  end
end
