SS::Application.routes.draw do

  Inquiry::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  concern :trash do
    get :trash, on: :collection
    delete :trash, action: :destroy_all, on: :collection
    match :soft_delete, on: :member, via: [:get, :post]
    match :undo_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :download do
    get :download, on: :collection
  end

  content "inquiry" do
    get "/" => redirect { |p, req| "#{req.path}/columns" }, as: :main
    resources :nodes, concerns: [:deletion, :trash]
    resources :forms, concerns: :deletion
    resources :columns, concerns: :deletion
    resources :answers, concerns: [:deletion, :download], only: [:index, :show, :destroy]
    get "results" => "results#index", as: :results
    resources :feedbacks, only: [:index, :show]
    get "answers/:id/fileid/:fid/download" => "answers#download_afile"
  end

  node "inquiry" do
    get "form/(index.:format)" => "public#new", cell: "nodes/form"
    get "form/sent.html" => "public#sent", cell: "nodes/form"
    get "form/results.html" => "public#results", cell: "nodes/form"
    post "form/confirm.html" => "public#confirm", cell: "nodes/form"
    post "form/create.html" => "public#create", cell: "nodes/form"
    get "node/(index.:format)" => "public#index", cell: "nodes/node"
  end

  part "inquiry" do
    get "feedback" => "public#index", cell: "parts/feedback"
  end

end
