Rails.application.routes.draw do

  Contact::Initializer

  namespace "contact", path: ".s:site/contact" do
    resources :contacts, only: %i[index destroy]

    namespace "apis" do
      get "contacts" => "contacts#index"
    end
  end

end
