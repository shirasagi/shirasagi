SS::Application.routes.draw do

  Rdf::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  concern :import do
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :unlink do
    get :unlink, on: :member
    post :unlink, on: :member
  end

  namespace("rdf", path: ".s:site/rdf", module: "rdf") do
    resources :vocabs, concerns: [:deletion, :import]
    namespace "apis" do
      match "classes" => "classes#index", via: [:get, :post]
      # get "props" => "props#index"
    end
  end

  namespace("rdf/classes", as: "rdf_classes", path: ".s:site/rdf/vocab:vocab_id", module: "rdf") do
    resources :classes, concerns: :deletion
  end

  namespace("rdf/classes/props", as: "rdf_classes_props", path: ".s:site/rdf/vocab:vocab_id/class:class_id", module: "rdf") do
    resources :props, concerns: [:deletion, :unlink, :import]
  end

  namespace("rdf/props", as: "rdf_props", path: ".s:site/rdf/vocab:vocab_id", module: "rdf") do
    resources :props, concerns: :deletion
  end
end
