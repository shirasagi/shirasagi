Rails.application.routes.draw do

  Chorg::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  namespace('chorg', as: 'chorg', path: '.s:site/chorg', module: 'chorg') do
    get '/' => redirect { |p, req| "#{req.path}/revisions" }, as: :main
    resources :revisions, concerns: [:deletion] do
      post :download_changesets, on: :member
      get :download_sample_csv, on: :collection
      match :import_changesets, on: :member, via: %i[get post]
    end
    resources :changesets, path: 'revisions/:rid/:type/changesets', concerns: [:deletion]
    resource :result, path: 'revisions/:rid/:type/result', only: [:show] do
      post :interrupt, on: :member
      post :reset, on: :member
    end

    resources :entity_logs, path: 'revisions/:rid/:type/entity_logs', only: [:show] do
      get :show_models, on: :collection, path: 'show_models/:entity_site'
      get :show_entities, on: :collection, path: 'show_entities/:entity_site/:entity_model'
      get :show_entity, on: :collection, path: 'show_entity/:entity_site/:entity_model/:entity_index'
      post :download, on: :collection
    end
    get 'revisions/:rid/:type/run' => 'run#confirmation', as: :run_confirmation
    post 'revisions/:rid/:type/run' => 'run#run', as: :run

    namespace 'frames' do
      scope module: 'changesets', as: "changesets" do
        resources :adds, path: 'revisions/:rid/add/changesets', except: %i[index destroy]
        resources :moves, path: 'revisions/:rid/move/changesets', except: %i[index destroy]
        resources :unifies, path: 'revisions/:rid/unify/changesets', except: %i[index destroy]
        resources :divisions, path: 'revisions/:rid/division/changesets', except: %i[index destroy]
        resources :deletes, path: 'revisions/:rid/delete/changesets', except: %i[index destroy]
      end
    end
  end
end
