SS::Application.routes.draw do

  Webmail::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, on: :collection
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

    resources :mails, concerns: [:deletion, :mail], path: 'mails/:mailbox',
      mailbox: /[^\/]+/, defaults: { mailbox: 'INBOX' }
    resources :mailboxes, concerns: [:deletion, :mailbox]
    resources :addresses, concerns: [:deletion, :export]
    resources :address_groups, concerns: [:deletion]
    resources :signatures, concerns: [:deletion]
    resources :filters, concerns: [:deletion, :filter]
    resource :cache_setting, only: [:show, :update]
    resource :account_setting, only: [:show, :edit, :update] do
      post :test_connection, :on => :member
    end
    resources :sys_notices, only: [:index, :show]

    # with group
    scope(path: "address_group-:group", as: "group") do
      resources :addresses, concerns: [:deletion, :export]
    end

    namespace "apis" do
      get "recent" => "imap#recent"
      get "quota" => "imap#quota"
      get "addresses" => "addresses#index"
    end
  end
end
