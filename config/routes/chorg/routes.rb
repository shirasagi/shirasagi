SS::Application.routes.draw do

  # Chorg::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  namespace("chorg_results", path: ".:site/chorgs/revisions/:rid", module: "chorg", id: /\w+/) do
    resources :results, only: [:index, :show]
  end

  namespace("chorg_revisions", path: ".:site/chorgs", module: "chorg") do
    resources :revisions, concerns: :deletion
  end

  namespace("chorg_changesets", path: ".:site/chorgs/revision:rid/:type", module: "chorg", rid: /\w+/, type: /\w+/) do
    resources :changesets, concerns: :deletion
  end

  namespace("chorg_run", path: ".:site/chorgs/revision:rid/:type", module: "chorg", rid: /\w+/, type: /\w+/) do
    get "confirmation" => "run#confirmation"
    post "run" => "run#run"
  end
end
