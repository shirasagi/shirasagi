SS::Application.routes.draw do
  Gws::Chorg::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  gws 'chorg' do
    get '/' => redirect { |p, req| "#{req.path}/revisions" }, as: :main
    resources :revisions, concerns: [:deletion]
    resources :changesets, path: 'revisions/:rid/:type/changesets', concerns: [:deletion]
    resource :result, path: 'revisions/:rid/:type/results', only: [:show] do
      post :interrupt, on: :member
      post :reset, on: :member
    end
    resources :entity_logs, path: 'revisions/:rid/:type/entity_logs', only: [:index, :show]
    get 'revisions/:rid/:type/run' => 'run#confirmation'
    post 'revisions/:rid/:type/run' => 'run#run'
  end
end
