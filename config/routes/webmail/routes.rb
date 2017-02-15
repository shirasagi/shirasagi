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

  concern :filter do
    post :apply, :on => :member
  end

  namespace "webmail", path: ".webmail" do
    get "/" => redirect { |p, req| "#{req.path}/user_profile" }, as: :cur_user

    resources :mails, concerns: [:deletion, :mail], path: 'mails/:mailbox',
      mailbox: /[^\/]+/, defaults: { mailbox: 'INBOX' }
    resources :mailboxes, concerns: [:deletion]
    resources :addresses, concerns: [:deletion]
    resources :signatures, concerns: [:deletion]
    resources :filters, concerns: [:deletion, :filter]
    resource :cache_setting, only: [:show, :update]
    resource :account_setting, only: [:show, :edit, :update] do
      post :test_connection, :on => :member
    end

    namespace "apis" do
      get "addresses" => "addresses#index"
    end
  end
end
