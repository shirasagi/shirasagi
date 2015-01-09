SS::Application.routes.draw do

  #Job::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  sys "job" do
    get "logs" => "logs#index"

    get "logs/batch_destroy" => "logs#batch_destroy", as: :batch_destroy
    post "logs/batch_destroy" => "logs#batch_destroy"

    get "logs/download" => "logs#download", as: :download
    post "logs/download" => "logs#download"

    get "logs/:id" => "logs#show"
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
