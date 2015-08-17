SS::Application.routes.draw do

  Contact::Initializer

  namespace "contact", path: ".s:site/contact" do
    get "/" => "main#index"
    get "/search_groups" => "search_groups#index"
  end

end
