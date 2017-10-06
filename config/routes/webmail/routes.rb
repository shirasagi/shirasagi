SS::Application.routes.draw do

  Webmail::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, on: :collection
  end

  concern :mail do
    collection do
      put :set_seen
      put :unset_seen
      put :set_star
      put :unset_star
      put :move
      put :copy
      delete :empty
    end
    member do
      get :download
      get :parts, path: 'parts/:section', format: false, section: /[^\/]+/
      get :header_view
      get :source_view
      put :set_seen
      put :unset_seen
      put :set_star
      put :unset_star
      put :move
      put :copy
      get :reply
      get :reply_all
      get :forward
    end
  end

  concern :mailbox do
    get :reload, :on => :collection
    post :reload, :on => :collection
  end

  concern :filter do
    post :apply, :on => :member
  end

  namespace "webmail", path: ".webmail" do
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }, as: :cur_user

    resources :mails, concerns: [:deletion, :mail], path: 'account:account/mails/:mailbox',
      account: /\d+/, mailbox: /[^\/]+/, defaults: { mailbox: 'INBOX' }
    resources :mailboxes, path: 'account:account/mailboxes', account: /\d+/, concerns: [:deletion, :mailbox]
    resources :addresses, path: 'account:account/addresses', account: /\d+/, concerns: [:deletion]
    resources :signatures, path: 'account:account/signatures', account: /\d+/, concerns: [:deletion]
    resources :filters, path: 'account:account/filters', concerns: [:deletion, :filter]
    resource :cache_setting, path: 'account:account/cache_setting', only: [:show, :update]
    resource :account_setting, only: [:show, :edit, :update] do
      post :test_connection, :on => :member
    end
    resources :sys_notices, only: [:index, :show]

    namespace "apis" do
      get "account:account/recent" => "imap#recent", account: /\d+/, as: :recent
      get "account:account/quota" => "imap#quota", account: /\d+/, as: :quota
      get "addresses" => "addresses#index"
    end
  end
end
