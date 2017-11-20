SS::Application.routes.draw do
  Gws::Elasticsearch::Initializer

  gws 'elasticsearch' do
    namespace :search do
      get '/' => redirect { |p, req| "#{req.path}/all" }, as: :main
      resource :search, path: ':type', only: [:show]
    end
  end
end
