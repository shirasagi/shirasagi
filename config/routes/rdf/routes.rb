SS::Application.routes.draw do

  Rdf::Initializer

  concern :deletion do
    get :delete, on: :member
  end

  namespace("rdf", path: ".:site/rdf", module: "rdf") do
    resources :vocabs, concerns: :deletion
    namespace "apis" do
      get "classes" => "classes#index"
      get "props" => "props#index"
    end
  end

  namespace("rdf/classes", as: "rdf_classes", path: ".:site/rdf/vocab:vid", module: "rdf") do
    resources :classes, concerns: :deletion
  end

  namespace("rdf/props", as: "rdf_props", path: ".:site/rdf/vocab:vid", module: "rdf") do
    resources :props, concerns: :deletion
  end
end
