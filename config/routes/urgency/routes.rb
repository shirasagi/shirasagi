# coding: utf-8
SS::Application.routes.draw do
  
  Urgency::Initializer
  
  concern :deletion do
    get :delete, on: :member
  end
  
  content "urgency" do
    get "/" => "main#index", as: :main
    resources :layouts, only: [:index, :show, :update]
    resources :errors, only: :show
  end
  
  node "urgency" do
    get "layout/layout-:layout.html" => "public#index", cell: "nodes/layout",
      layout: /\d+/
  end
  
end
