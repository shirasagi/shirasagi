# coding: utf-8
SS::Application.routes.draw do

  #History::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  sys "history" do
    get "logs" => "logs#index", as: :logs
    get "logs/delete" => "logs#delete", as: :delete
    delete "logs" => "logs#destroy", as: :destroy
    get "logs/download" => "logs#download", as: :download
    post "logs/download" => "logs#download"
  end

  namespace "history", path: ".:site/history" do
    get "logs" => "logs#index"
    get "logs/delete" => "logs#delete", as: :delete
    delete "logs" => "logs#destroy", as: :destroy
    get "logs/download" => "logs#download", as: :download
    post "logs/download" => "logs#download"
  end
end
