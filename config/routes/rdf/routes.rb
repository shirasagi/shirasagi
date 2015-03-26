SS::Application.routes.draw do

  Rdf::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  namespace("rdf", path: ".:site/rdf", module: "rdf") do
    resources :vocabs, concerns: :deletion
    get "search_classes" => "search_classes#index"
    get "search_props" => "search_props#index"
  end

  namespace("rdf/classes", as: "rdf_classes", path: ".:site/rdf/vocab:vid", module: "rdf") do
    resources :classes, concerns: :deletion
  end

  namespace("rdf/props", as: "rdf_props", path: ".:site/rdf/vocab:vid", module: "rdf") do
    resources :props, concerns: :deletion
  end
end
