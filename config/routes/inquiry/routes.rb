Rails.application.routes.draw do

  Inquiry::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :change_state do
    get :state, on: :member
    put :change_state_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :collection
  end

  content "inquiry" do
    get "/" => redirect { |p, req| "#{req.path}/columns" }, as: :main
    resources :nodes, concerns: [:deletion, :change_state]
    resources :forms, only: [:index]
    resources :columns, concerns: :deletion
    resources :answers, concerns: [:deletion, :download], only: [:index, :show, :edit, :update, :destroy] do
      get :download_afile, on: :member, path: "/fileid/:fid/download"
    end
    get "results" => "results#index", as: :results
    get "results/download" => "results#download", as: :results_download
    resources :feedbacks, only: [:index, :show]
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

  namespace "inquiry", path: ".s:site/inquiry" do
    resources :site_answers, path: "answers", concerns: [:deletion, :download], only: %i[index show edit update destroy] do
      get :download_afile, on: :member, path: "/fileid/:fid/download"
    end
  end

end
