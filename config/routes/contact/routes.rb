Rails.application.routes.draw do

  Contact::Initializer

  namespace "contact", path: ".s:site/contact" do
    namespace "apis" do
      get "contacts" => "contacts#index"
    end
  end

end
