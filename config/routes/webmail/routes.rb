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
      get :parts_batch_download
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
      get :edit_as_new
      get :print
      put :send_mdn
      put :ignore_mdn
      resources :gws_messages, path: 'messages/g:site', site: /\d+/, only: [:new, :create]
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

    resources :groups, concerns: [:deletion, :export] do
      get :download_template, on: :collection
      resource :account, controller: "group_accounts", except: [:new, :create] do
        get :delete, on: :member
        post :test_connection, on: :collection
      end
    end
    resources :users, concerns: [:deletion, :export] do
      get :download_template, on: :collection
      resources :accounts, concerns: [:deletion], controller: "user_accounts" do
        post :test_connection, on: :collection
      end
    end
    resources :roles, concerns: [:deletion, :export]

    resources :histories, only: [:index]
    resources :histories, only: [:index, :show], path: 'histories/:ymd', as: :daily_histories do
      match :download, on: :collection, via: [:get, :post]
    end
    resources :history_archives, concerns: [:deletion], only: [:index, :show, :destroy]

    get "addresses" => "addresses#index", as: "addresses_main"
    resources :addresses, path: "addresses/:group", concerns: [:deletion, :export] do
      get :add, on: :collection
      put :move, path: 'move/:group_id', group_id: /\d+/, on: :collection
    end
    resources :address_groups, concerns: [:deletion]

    resource :account, only: [:show, :edit, :update], path: ':webmail_mode-:account/account',
      webmail_mode: /[a-z]+/, account: /\d+/, defaults: { webmail_mode: 'account' } do
      post :test_connection, on: :member
    end
    resources :mails, concerns: [:deletion, :mail], path: ':webmail_mode-:account/mails/:mailbox',
      webmail_mode: /[a-z]+/, account: /\d+/, mailbox: /[^\/]+/, defaults: { webmail_mode: 'account', mailbox: 'INBOX' }
    resources :mailboxes, path: ':webmail_mode-:account/mailboxes',
      webmail_mode: /[a-z]+/, account: /\d+/, concerns: [:deletion, :mailbox], defaults: { webmail_mode: 'account' }
    resources :signatures, path: ':webmail_mode-:account/signatures',
      webmail_mode: /[a-z]+/, account: /\d+/, concerns: [:deletion], defaults: { webmail_mode: 'account' }
    resources :filters, path: ':webmail_mode-:account/filters',
      webmail_mode: /[a-z]+/, concerns: [:deletion, :export, :filter], defaults: { webmail_mode: 'account' }
    resource :cache_setting, path: ':webmail_mode-:account/cache_setting', only: [:show, :update],
      webmail_mode: /[a-z]+/, defaults: { webmail_mode: 'account' }
    resources :import_mails, only: :index, path: ':webmail_mode-:account/import_mails',
      webmail_mode: /[a-z]+/, account: /\d+/, concerns: [:deletion], defaults: { webmail_mode: 'account' } do
      put :import, on: :collection
    end
    resources :export_mails, only: :index, path: ':webmail_mode-:account/export_mails',
      webmail_mode: /[a-z]+/, account: /\d+/, concerns: [:deletion], defaults: { webmail_mode: 'account' } do
      put :export, on: :collection
      get :start_export, on: :collection
    end

    resources :sys_notices, only: [:index, :show]

    namespace "apis" do
      get ":webmail_mode-:account/recent" => "imap#recent",
        webmail_mode: /[a-z]+/, account: /\d+/, as: :recent, defaults: { webmail_mode: 'account' }
      get ":webmail_mode-:account/latest" => "imap#latest",
        webmail_mode: /[a-z]+/, account: /\d+/, defaults: { webmail_mode: 'account' }
      get ":webmail_mode-:account/quota" => "imap#quota",
        webmail_mode: /[a-z]+/, account: /\d+/, as: :quota, defaults: { webmail_mode: 'account' }
      get ":webmail_mode-:account/mails" => "mails#index",
        webmail_mode: /[a-z]+/, account: /\d+/, as: :mails, defaults: { webmail_mode: 'account' }
      get ":webmail_mode-:account/mails/imap_error" => "mails#imap_error",
        webmail_mode: /[a-z]+/, account: /\d+/, as: :mails_imap_error, defaults: { webmail_mode: 'account' }
      get "addresses" => "addresses#index"
    end
  end
end
