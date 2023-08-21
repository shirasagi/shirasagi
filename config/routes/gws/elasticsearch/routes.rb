Rails.application.routes.draw do
  Gws::Elasticsearch::Initializer

  gws 'elasticsearch' do
    namespace :search do
      get '/' => redirect { |p, req| "#{req.path}/all" }, as: :main
      resource :search, path: ':type', only: [:show]
    end

    namespace :diagnostic do
      get '/' => redirect { |p, req| "#{req.path}/status" }, as: :main
      resource :status, only: [:show]
      resource :statistic, only: [:show]
      resource :analyzer, only: %i[edit update]
    end
  end
end
