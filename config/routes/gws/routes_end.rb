Rails.application.routes.draw do
  unless Rails.env.development?
    namespace "gws", path: ".g:site" do
      match "*private_path" => "catch_all#index", via: :all
    end
  end
end
