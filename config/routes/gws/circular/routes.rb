SS::Application.routes.draw do
  Gws::Circular::Initializer

  concern :deletion do
    get :delete, on: :member
    delete action: :destroy_all, on: :collection
  end

  gws 'circular' do
    resources :topics, concerns: [:deletion] do
      get :marking, on: :member
      get :unmarking, on: :member
      post :marking_all, on: :collection
      post :unmarking_all, on: :collection
      post :download, on: :collection
      namespace :parent, path: ':parent_id', parent_id: /\d+/ do
        resources :comments,
                  controller: '/gws/circular/comments',
                  concerns: [:deletion]
      end
    end

    namespace 'apis' do
      get 'marking' => 'topics#marking'
      get 'unmarking' => 'topics#unmarking'
    end
  end
end
