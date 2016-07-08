SS::Application.routes.draw do

  #Job::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  sys "job" do
    get "/" => redirect { |p, req| "#{req.path}/logs" }, as: :main

    resources :logs, only: [:index, :show] do
      get :batch_destroy, on: :collection
      post :batch_destroy, on: :collection
      get :download, on: :collection
      post :download, on: :collection
    end

    resources :tasks, only: [:index, :show, :destroy], concerns: [:deletion] do
      post :reset_state, on: :member
    end
  end

  cms "job" do
    get "logs" => "logs#index"

    get "logs/batch_destroy" => "logs#batch_destroy", as: :batch_destroy
    post "logs/batch_destroy" => "logs#batch_destroy"

    get "logs/download" => "logs#download", as: :download
    post "logs/download" => "logs#download"

    get "logs/:id" => "logs#show"
  end
end
