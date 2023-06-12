Rails.application.routes.draw do

  Contact::Initializer

  namespace "contact", path: ".s:site/contact" do
    resources :contacts, only: %i[index destroy]
    resource :unify, only: %i[show update], path: ":group_id/unify"

    namespace "apis" do
      get "contacts" => "contacts#index"
    end
  end

end
