SS::Application.routes.draw do
  Gws::Report::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'report' do
    get '/' => redirect { |p, req| "#{req.path}/forms" }, as: :setting
    resources :forms, concerns: :deletion do
      match :publish, on: :member, via: [:get, :post]
      match :depublish, on: :member, via: [:get, :post]
      resources :columns, concerns: :deletion
    end
  end
end
