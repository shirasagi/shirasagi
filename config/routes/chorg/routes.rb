SS::Application.routes.draw do

  Chorg::Initializer

  concern :deletion do
    get :delete, on: :member
    #delete action: :destroy_all, on: :collection
  end

  namespace('chorg', as: 'chorg', path: '.s:site/chorg', module: 'chorg') do
    get '/' => redirect { |p, req| "#{req.path}/revisions" }, as: :main
    resources :revisions, concerns: [:deletion]
    resources :changesets, path: 'revisions/:rid/:type/changesets', concerns: [:deletion]
    resource :result, path: 'revisions/:rid/:type/result', only: [:show] do
      post :interrupt, on: :member
      post :reset, on: :member
    end
    resources :entity_logs, path: 'revisions/:rid/:type/entity_logs', only: [:index, :show]
    get 'revisions/:rid/:type/run' => 'run#confirmation', as: :run_confirmation
    post 'revisions/:rid/:type/run' => 'run#run', as: :run
  end
end
