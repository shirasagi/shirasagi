SS::Application.routes.draw do

  Multilingual::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
  end

  namespace "multilingual", path: ".s:site/multilingual" do
    scope "page:native_id/:lang" do
      resources :pages, concerns: :deletion
    end

    scope "node:native_id/:lang" do
      resources :nodes, concerns: :deletion
    end

    scope "part:native_id/:lang" do
      resources :parts, concerns: :deletion
    end
  end

  content "multilingual" do
    get "/" => redirect { multilingual_langs_path }, as: :main
    resources :langs, concerns: :deletion

    namespace "node", path: "" do
      scope "page:native_id/:lang" do
        resources :pages, concerns: :deletion
      end

      scope "node:native_id/:lang" do
        resources :nodes, concerns: :deletion
      end

      scope "part:native_id/:lang" do
        resources :parts, concerns: :deletion
      end
    end
  end

end
