SS::Application.routes.draw do

  Contact::Initializer

  namespace "contact", path: ".:site/contact" do
    get "/" => "main#index"
    get "/search_groups" => "search_groups#index"
  end

end
