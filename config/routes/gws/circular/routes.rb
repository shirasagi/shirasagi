SS::Application.routes.draw do
  Gws::Circular::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'circular' do
    resources :topics, concerns: [:deletion] do
      get :mark, on: :member
      get :unmark, on: :member
      post :mark_all, on: :collection
      post :unmark_all, on: :collection
      post :download, on: :collection
      namespace :parent, path: ':parent_id', parent_id: /\d+/ do
        resources :comments,
                  controller: '/gws/circular/comments',
                  concerns: [:deletion]
      end
    end

    namespace 'apis' do
      get 'mark' => 'topics#mark'
      get 'unmark' => 'topics#unmark'
    end
  end
end
