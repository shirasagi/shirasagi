SS::Application.routes.draw do

  #History::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, :on => :collection
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
  end
end
