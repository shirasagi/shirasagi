SS::Application.routes.draw do

  Webmail::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :export do
    get :download, on: :collection
    get :import, on: :collection
    post :import, on: :collection
  end

  concern :mail do
    collection do
      put :set_seen
      put :unset_seen
      put :set_star
      put :unset_star
      put :move
      put :rename_mailbox
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
      put :send_mdn
      put :ignore_mdn
      resources :gws_messages, path: 'messages/g:site', site: /\d+/, only: [:new, :create]
    end
  end

  concern :group_mail do
    collection do
      put :set_seen
      put :unset_seen
      put :set_star
      put :unset_star
      put :move
      put :rename_mailbox
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
      put :send_mdn
      put :ignore_mdn
      resources :gws_group_messages, path: 'group_messages/g:site', site: /\d+/, only: [:new, :create]
    end
  end

  concern :mailbox do
    get :reload, on: :collection
    post :reload, on: :collection
  end

  concern :filter do
    post :apply, on: :member
  end

  namespace "webmail", path: ".webmail" do
    get "/" => "main#index", as: :main
    match "logout" => "login#logout", as: :logout, via: [:get]
    match "login"  => "login#login", as: :login, via: [:get, :post]

    resources :users, concerns: [:deletion, :export] do
      get :download_template, on: :collection
    end
    resources :roles, concerns: [:deletion, :export]

    resources :histories, only: [:index]
    resources :histories, only: [:index, :show], path: 'histories/:ymd', as: :daily_histories do
      match :download, on: :collection, via: [:get, :post]
    end
    resources :history_archives, concerns: [:deletion], only: [:index, :show, :destroy]

    resources :mails, concerns: [:deletion, :mail], path: 'account-:account/mails/:mailbox',
      account: /\d+/, mailbox: /[^\/]+/, defaults: { mailbox: 'INBOX' }
    resources :group_mails, concerns: [:deletion, :group_mail], path: 'group:group/mails/:mailbox',
      group: /\d+/, mailbox: /[^\/]+/, defaults: { mailbox: 'INBOX' }
    resources :mailboxes, path: 'account-:account/mailboxes', account: /\d+/, concerns: [:deletion, :mailbox]
    resources :group_mailboxes, path: 'group:group/mailboxes', group: /\d+/, concerns: [:deletion, :mailbox]
    resources :addresses, path: 'account-:account/addresses', account: /\d+/, concerns: [:deletion, :export] do
      get :add, on: :collection
    end
    resources :group_addresses, path: 'group:group/addresses', group: /\d+/, concerns: [:deletion, :export] do
      get :add, on: :collection
    end
    resources :address_groups, path: 'account-:account/addresses_groups', account: /\d+/, concerns: [:deletion]
    resources :group_address_groups, path: 'group:group/addresses_groups', group: /\d+/, concerns: [:deletion]
    resources :signatures, path: 'account-:account/signatures', account: /\d+/, concerns: [:deletion]
    resources :group_signatures, path: 'group:group/signatures', account: /\d+/, concerns: [:deletion]
    resources :filters, path: 'account-:account/filters', concerns: [:deletion, :export, :filter]
    resources :group_filters, path: 'group:group/filters', concerns: [:deletion, :export, :filter]
    resource :cache_setting, path: 'account-:account/cache_setting', only: [:show, :update]
    resource :group_cache_setting, path: 'group:group/cache_setting', only: [:show, :update]
    resource :account_setting, only: [:show, :edit, :update] do
      post :test_connection, on: :member
    end
    get :login_failed, to: "login_failed#index", path: 'account-:account/login_failed', account: /\d+/
    get :group_login_failed, to: "group_login_failed#index", path: 'group:group/login_failed', group: /\d+/
    resources :sys_notices, only: [:index, :show]

    # with group
    scope(path: "account-:account/address_group-:address_group", as: "address_group") do
      resources :addresses, concerns: [:deletion, :export]
    end

    scope(path: "group:group/address_group-:address_group", as: "address_group") do
      resources :group_addresses, concerns: [:deletion, :export]
    end

    namespace "apis" do
      get "account-:account/recent" => "imap#recent", account: /\d+/, as: :recent
      get "account-:account/latest" => "imap#latest", account: /\d+/
      get "group:group/recent" => "group_imap#recent", group: /\d+/, as: :group_recent
      get "account-:account/quota" => "imap#quota", account: /\d+/, as: :quota
      get "addresses" => "addresses#index"
    end
  end
end
