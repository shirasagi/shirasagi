SS::Application.routes.draw do
  Gws::Board::Initializer

  gws "board" do
    resources :topics do
      get :delete, on: :member
      namespace :parent, path: ":parent_id", parent_id: /\d+/ do
        resources :comments, controller: '/gws/board/comments' do
          get :delete, on: :member
        end
      end
    end
  end
end
