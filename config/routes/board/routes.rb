SS::Application.routes.draw do

  Board::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :download do
    get :download, :on => :collection
  end

  concern :reply do
    get :new_reply, on: :member
    post :reply, on: :member
  end

  content "board" do
    get "/" => redirect { |p, req| "#{req.path}/posts" }, as: :main
    resources :posts, concerns: [:deletion, :download, :reply]
    resources :anpi_posts, only: [:index]
  end

  node "board" do
    get "post/(index.:format)" => "public#index", cell: "nodes/post"
    get "post/new" => "public#new", cell: "nodes/post"
    get "post/sent" => "public#sent", cell: "nodes/post"
    post "post/create" => "public#create", cell: "nodes/post"
    get "post/:parent_id/new" => "public#new_reply", cell: "nodes/post"
    post "post/:parent_id/create" => "public#reply", cell: "nodes/post"
    get "post/:parent_id/delete" => "public#delete", cell: "nodes/post"
    delete "post/:parent_id/destroy" => "public#destroy", cell: "nodes/post"

    get "post/search" => "public#search", cell: "nodes/post"

    #get "post/:parent_id(index.:format)" => "public#show", cell: "nodes/post"             #post show
    #get "post/:parent_id/:comment_id(index.:format)" => "public#show", cell: "nodes/post" #comment show

    get "anpi_post/(index.:format)" => "public#index", cell: "nodes/anpi_post"
    post "anpi_post/(index.:format)" => "public#index", cell: "nodes/anpi_post"
  end

end
