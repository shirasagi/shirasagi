Rails.application.routes.draw do

  History::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  sys "history" do
    get "logs" => "logs#index", as: :logs
    get "logs/delete" => "logs#delete", as: :delete
    delete "logs" => "logs#destroy", as: :destroy

    get "logs/download" => "logs#download", as: :download
    post "logs/download" => "logs#download"
  end

  cms "history" do
    get "logs" => "logs#index"
    get "logs/delete" => "logs#delete", as: :delete
    delete "logs" => "logs#destroy", as: :destroy

    get "logs/download" => "logs#download", as: :download
    post "logs/download" => "logs#download"

    get "backups/:source/:id" => "backups#show", as: :backup, source: /[^\/]+/
    put "backups/:source/:id" => "backups#update", source: /[^\/]+/
    get "backups/:source/:id/restore" => "backups#restore", as: :restore, source: /[^\/]+/
    get "backups/:source/:id/change" => "backups#change", as: :change, source: /[^\/]+/

    resources :trashes, only: [:index, :show, :destroy], concerns: :deletion do
      match :undo_delete, on: :member, via: [:get, :delete]
      post :undo_delete_all, on: :collection
    end
  end
end
