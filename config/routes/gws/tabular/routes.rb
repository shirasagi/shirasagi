Rails.application.routes.draw do
  Gws::Tabular::Initializer

  gws 'tabular' do
    resources :spaces, only: %i[index]
    scope ':space' do
      resource :main, only: %i[show]
      scope ':form/:view' do
        resources :files do
          match :download_all, on: :collection, via: %i[get post]
          match :import, on: :collection, via: %i[get post]
          match :copy, on: :member, via: %i[get post]
        end
        resources :trash_files, only: %i[index show destroy] do
          post :undo_delete, on: :member
        end

        namespace :frames do
          resources :approvers, only: %i[show update] do
            post :cancel, on: :member
            put :restart, on: :member
          end
          resources :inspections, only: %i[edit update] do
            post :reroute, on: :member
          end
          resources :circulations, only: %i[update]
          resources :destination_states, only: %i[show update]
        end
      end
    end

    namespace :apis do
      scope ':space/:form/:view' do
        resources :files, only: %i[index]
      end
      namespace :gws do
        scope ':space' do
          resources :forms, only: %i[index]
          scope 'forms/:form' do
            resources :columns, only: %i[edit update]
          end
        end
      end
    end

    namespace :gws do
      get '/' => redirect { |p, req| "#{req.path}/spaces" }, as: :main
      resources :spaces, except: %i[destroy] do
        match :soft_delete, on: :member, via: %i[get post]
      end
      resources :trash_spaces, only: %i[index show] do
        match :undo_delete, on: :member, via: %i[get post]
      end
      scope ':space' do
        resources :forms, except: %i[destroy] do
          match :soft_delete, on: :member, via: %i[get post]
          match :publish, on: :member, via: %i[get post]
          match :depublish, on: :member, via: %i[get post]
          resources :columns, only: %i[index create] do
            post :reorder, on: :collection
          end
        end
        resources :trash_forms, only: %i[index show] do
          match :undo_delete, on: :member, via: %i[get post]
        end
        resources :views do
          get :delete, on: :member
        end
      end
    end
    namespace :frames do
      namespace :gws do
        scope ':space/:form' do
          resources :lookup_columns, only: %i[index]

          resources :columns, only: %i[show edit update destroy] do
            get :detail, on: :member
            post :change_type, on: :member
          end
        end
      end
    end
  end
end
