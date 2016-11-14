SS::Application.routes.draw do

  Webmail::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, :on => :collection
  end

  concern :mail do
    get :download, :on => :member
    get :attachment, :on => :member
    get :header_view, :on => :member
    get :source_view, :on => :member
    get :set_seen, :on => :member
    get :unset_seen, :on => :member
    get :set_star, :on => :member
    get :unset_star, :on => :member
  end

  namespace "webmail", path: ".webmail" do
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }, as: :cur_user

    resources :mails, concerns: [:deletion, :mail], path: 'mails/:box', box: /[^\/]+/, defaults: { box: 'INBOX' }
    resource :account_setting, only: [:show, :edit, :update]
    resource :cache_setting, only: [:show, :update]
  end
end
