# coding: utf-8
SS::Application.routes.draw do

  #History::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  namespace "history", path: ".:host/history" do
    get "/" => "main#index"

    #resources :logs, concerns: :deletion
    get "logs" => "logs#index"
    get "logs/delete" => "logs#delete", as: :delete
    delete "logs" => "logs#destroy", as: :destroy
  end
end
