SS::Application.routes.draw do

  Uploader::Initializer

  content "uploader" do
    get "/" => redirect { |p, req| "#{req.path}/files" }, as: :main
    get "files" => "files#index"
    get "files/*filename" => "files#file", format: false
    resource :files, path: '/files/*filename', as: :files, only: [:create, :destroy, :update], format: false
  end

  node "uploader" do
    get "file/(index.:format)" => "public#index", cell: "nodes/file"
  end

end
