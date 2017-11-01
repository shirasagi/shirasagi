SS::Application.routes.draw do
  Gws::Elasticsearch::Initializer

  # concern :deletion do
  #   get :delete, on: :member
  #   delete action: :destroy_all, on: :collection
  # end

  gws 'elasticsearch' do
    resource :setting, only: [:show, :edit, :update]
    namespace :search do
      get '/' => redirect { |p, req| "#{req.path}/all" }, as: :main
      resource :search, path: ':type', only: [:show]
    end

    # namespace "apis" do
    #   get "categories" => "categories#index"
    # end
  end
end
