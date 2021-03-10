Rails.application.routes.draw do
  Gws::Chorg::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :download do
    get :download, on: :member
    get :download_sample_csv, on: :collection
  end

  gws 'chorg' do
    get '/' => redirect { |p, req| "#{req.path}/revisions" }, as: :main
    resources :revisions, concerns: [:deletion, :download]
    resources :changesets, path: 'revisions/:rid/:type/changesets', concerns: [:deletion]
    resource :result, path: 'revisions/:rid/:type/results', only: [:show] do
      post :interrupt, on: :member
      post :reset, on: :member
    end
    resources :entity_logs, path: 'revisions/:rid/:type/entity_logs', only: [:index, :show] do
      get :show_models, on: :collection, path: 'show_models/:entity_site'
      get :show_entities, on: :collection, path: 'show_entities/:entity_site/:entity_model'
      get :show_entity, on: :collection, path: 'show_entity/:entity_site/:entity_model/:entity_index'
    end
    get 'revisions/:rid/:type/run' => 'run#confirmation'
    post 'revisions/:rid/:type/run' => 'run#run'
  end
end
