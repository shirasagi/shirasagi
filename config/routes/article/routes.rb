Rails.application.routes.draw do

  Article::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :copy do
    get :copy, on: :member
    put :copy, on: :member
  end

  concern :move do
    get :move, on: :member
    put :move, on: :member
  end

  concern :lock do
    get :lock, on: :member
    delete :lock, action: :unlock, on: :member
  end

  concern :download_all do
    match :download_all, on: :collection, via: %i[get post]
  end

  concern :import do
    match :import, on: :collection, via: %i[get post]
  end

  concern :command do
    get :command, on: :member
    post :command, on: :member
  end

  concern :opendata_ref do
    post :update_opendata_resources, on: :member
  end

  concern :contains_urls do
    get :contains_urls, on: :member
  end

  concern :tag do
    post :tag, action: :set_tag_all, on: :collection
    delete :tag, action: :reset_tag_all, on: :collection
  end

  concern :michecker do
    get :michecker, action: :michecker, on: :member
    get :michecker_lowvision_result, action: :michecker_lowvision_result, on: :member
  end

  content "article" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    get "generate" => "generate#index"
    post "generate" => "generate#run"
    resources :pages, concerns: [
      :deletion, :copy, :move, :lock, :download_all, :import, :command, :opendata_ref, :contains_urls, :tag, :michecker
    ]
  end

  content "article" do
    get "index_approve" => "pages#index_approve"
    get "index_request" => "pages#index_request"
    get "index_ready" => "pages#index_ready"
    get "index_closed" => "pages#index_closed"
    get 'index_wait_close' => 'pages#index_wait_close'
    delete "index_:state" => "pages#destroy_all", state: /approve|request|ready|closed|wait_close/
  end

  node "article" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  part "article" do
    get "page" => "public#index", cell: "parts/page"
    get "page_navi" => "public#index", cell: "parts/page_navi"
  end

  page "article" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

end
