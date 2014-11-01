SS::Application.routes.draw do

  Inquiry::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  content "inquiry" do
    get "/" => redirect { |p, req| "#{req.path}/columns" }, as: :main
    resources :forms, concerns: :deletion
    resources :columns, concerns: :deletion
    resources :answers, concerns: :deletion, only: [:index, :show, :destroy]
  end

  node "inquiry" do
    get "form/(index.:format)" => "public#new", cell: "nodes/form"
    get "form/sent.html" => "public#sent", cell: "nodes/form"
    post "form/confirm.html" => "public#confirm", cell: "nodes/form"
    post "form/create.html" => "public#create", cell: "nodes/form"
  end

end
