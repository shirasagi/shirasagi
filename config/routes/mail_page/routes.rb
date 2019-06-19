SS::Application.routes.draw do

  MailPage::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :lock do
    get :lock, on: :member
    delete :lock, action: :unlock, on: :member
  end

  concern :copy do
    get :copy, on: :member
    put :copy, on: :member
  end

  content "mail_page" do
    get "/" => redirect { |p, req| "#{req.path}/pages" }, as: :main
    resources :pages, concerns: [:deletion, :lock, :copy]
  end

  node "mail_page" do
    get "page/(index.:format)" => "public#index", cell: "nodes/page"
    get "page/rss.xml" => "public#rss", cell: "nodes/page", format: "xml"
  end

  page "mail_page" do
    get "page/:filename.:format" => "public#index", cell: "pages/page"
  end

  part "mail_page" do
    get "page" => "public#index", cell: "parts/page"
  end

end
