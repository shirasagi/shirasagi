SS::Application.routes.draw do
  Gws::Chorg::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'chorg' do
    get '/' => redirect { |p, req| "#{req.path}/revisions" }, as: :main
    resources :revisions, concerns: [:deletion] do
      # resources :results, only: [:index, :show]
    end
    resources :changesets, path: 'revision:rid/:type/changesets', concerns: [:deletion]
    resources :results, path: 'revision:rid/results', only: [:index, :show]
    get 'revision:rid/:type/run' => 'run#confirmation'
    post 'revision:rid/:type/run' => 'run#run'
  end
end
