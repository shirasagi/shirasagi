SS::Application.routes.draw do

  KeyVisual::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :trash do
    get :trash, on: :collection
    delete :trash, action: :destroy_all, on: :collection
    match :soft_delete, on: :member, via: [:get, :post]
    match :undo_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  content "key_visual" do
    get "/" => redirect { |p, req| "#{req.path}/images" }, as: :main
    resources :images, concerns: [:deletion, :trash]
  end

  node "key_visual" do
    get "image/" => "public#index", cell: "nodes/image"
  end

  part "key_visual" do
    get "slide" => "public#index", cell: "parts/slide"
  end

  page "key_visual" do
    get "image/:filename.:format" => "public#index", cell: "pages/image"
  end

end
