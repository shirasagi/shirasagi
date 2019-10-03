Rails.application.routes.draw do
  unless Rails.env.development?
    match "*private_path" => "sns/catch_all#index", via: :all, private_path: /\..*/
  end
end
