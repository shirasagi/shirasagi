Rails.application.routes.draw do
  unless Rails.env.development?
    namespace "webmail", path: ".webmail" do
      match "*private_path" => "catch_all#index", via: :all
    end
  end
end
