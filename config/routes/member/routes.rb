SS::Application.routes.draw do

  Member::Initializer

  concern :deletion do
    get :delete, :on => :member
    delete action: :destroy_all, :on => :collection
  end

  concern :download do
    get :download, :on => :collection
  end

  # Google Person Finder
  concern :gpf do
    get :gpf, action: :edit_gpf, on: :member
    post :gpf, action: :update_gpf, on: :member
  end

  content "member" do
    get "/" => redirect { |p, req| "#{req.path}/logins" }, as: :main
    resources :logins, only: [:index]
    resources :mypages, concerns: :deletion
    resources :my_profiles, concerns: :deletion
    resources :my_blogs, concerns: :deletion
    resources :my_photos, concerns: :deletion
    resources :my_anpi_posts, concerns: [:deletion, :download, :gpf]
    resources :my_groups, concerns: :deletion
    resources :blog_layouts, concerns: :deletion
    resources :blogs, concerns: :deletion
    resources :blog_pages, concerns: :deletion
    resources :blog_page_locations, concerns: :deletion

    resources :photos, concerns: :deletion do
      get :index_listable, on: :collection
      get :index_slideable, on: :collection
    end
    resources :photo_searches, concerns: :deletion
    resources :photo_categories, concerns: :deletion
    resources :photo_locations, concerns: :deletion
    resources :photo_spots, concerns: :deletion
    resources :registrations, concerns: :deletion

    # resources :groups, concerns: :deletion do
    #   resources :members, controller: :group_members, concerns: :deletion
    # end
  end

  node "member" do
    ## login
    match "login/(index.:format)" => "public#login", via: [:get, :post], cell: "nodes/login"
    match "login/login.html" => "public#login", via: [:get, :post], cell: "nodes/login"
    get "login/logout.html" => "public#logout", cell: "nodes/login"
    get "login/:provider/callback" => "public#callback", cell: "nodes/login"
    get "login/failure" => "public#failure", cell: "nodes/login"

    ## mypage node
    get "mypage/(index.:format)" => "public#index", cell: "nodes/mypage"

    ## public contents
    get "blog/(index.:format)" => "public#index", cell: "nodes/blog"
    get "blog/rss.xml" => "public#rss", cell: "nodes/blog", format: "xml"
    get "blog_page/(index.:format)" => "public#index", cell: "nodes/blog_page"
    get "blog_page/rss.xml" => "public#rss", cell: "nodes/blog_page", format: "xml"
    get "blog_page_location/(index.:format)" => "public#index", cell: "nodes/blog_page_location"
    get "blog_page/rss.xml" => "public#rss", cell: "nodes/blog_page_location", format: "xml"

    get "photo/(index.:format)" => "public#index", cell: "nodes/photo"
    get "photo/rss.xml" => "public#rss", cell: "nodes/photo", format: "xml"
    get "photo_search/(index.:format)" => "public#index", cell: "nodes/photo_search"
    get "photo_search/map.html" => "public#map", cell: "nodes/photo_search"
    get "photo_category/(index.:format)" => "public#index", cell: "nodes/photo_category"
    get "photo_location/(index.:format)" => "public#index", cell: "nodes/photo_location"
    get "photo_spot/(index.:format)" => "public#index", cell: "nodes/photo_spot"
    get "photo_spot/rss.xml" => "public#rss", cell: "nodes/photo_spot", format: "xml"

    ## mypage contents
    get "my_profile(index.:format)" => "public#index", cell: "nodes/my_profile"
    resource :my_profile, controller: "public", cell: "nodes/my_profile", only: [:edit, :update]
    get "my_profile/leave(.:format)" => "public#leave", cell: "nodes/my_profile"
    post "my_profile/confirm_leave(.:format)" => "public#confirm_leave", cell: "nodes/my_profile"
    post "my_profile/complete_leave(.:format)" => "public#complete_leave", cell: "nodes/my_profile"
    get "my_profile/change_password(.:format)" => "public#change_password", cell: "nodes/my_profile"
    post "my_profile/confirm_password(.:format)" => "public#confirm_password", cell: "nodes/my_profile"
    get "my_profile/complete_password(.:format)" => "public#complete_password", cell: "nodes/my_profile"
    post "my_profile/postal_code(.:format)" => "public#postal_code", cell: "nodes/my_profile"

    scope "my_blog" do
      resource :setting, controller: "public", cell: "nodes/my_blog/setting", except: [:index, :show, :destroy]
    end
    get "my_blog(index.:format)" => "public#index", cell: "nodes/my_blog"
    resources :my_blog, concerns: :deletion, controller: "public", cell: "nodes/my_blog", except: :index

    get "my_photo(index.:format)" => "public#index", cell: "nodes/my_photo"
    resources :my_photo, concerns: :deletion, controller: "public", cell: "nodes/my_photo", except: :index

    resources :my_anpi_post, concerns: :deletion, controller: "public", cell: "nodes/my_anpi_post" do
      get "others/new(.:format)", action: :others_new, on: :collection, as: :new_others
      post "others(.:format)", action: :others_create, on: :collection
      get "map", on: :collection
    end

    resources :my_group, concerns: :deletion, controller: "public", cell: "nodes/my_group" do
      get "invite(.:format)", action: :invite, on: :member
      post "invite(.:format)", action: :invite, on: :member
      get "accept(.:format)", action: :accept, on: :member
      post "accept(.:format)", action: :accept, on: :member
      get "reject(.:format)", action: :reject, on: :member
      post "reject(.:format)", action: :reject, on: :member
    end

    ## registration
    get "registration/(index.html)" => "public#new", cell: "nodes/registration"
    match "registration/new.html" => "public#new", cell: "nodes/registration", via: [:get, :post]
    post "registration/confirm.html" => "public#confirm", cell: "nodes/registration"
    post "registration/interim.:format" => "public#interim", cell: "nodes/registration"
    get "registration/verify(.:format)" => "public#verify", cell: "nodes/registration"
    post "registration/registration.:format" => "public#registration", cell: "nodes/registration"
    get "registration/send_again(.:format)" => "public#send_again", cell: "nodes/registration"
    post "registration/resend_confirmation_mail(.:format)" => "public#resend_confirmation_mail", cell: "nodes/registration"
    get "registration/reset_password(.:format)" => "public#reset_password", cell: "nodes/registration"
    post "registration/reset_password(.:format)" => "public#reset_password", cell: "nodes/registration"
    get "registration/confirm_reset_password(.:format)" => "public#confirm_reset_password", cell: "nodes/registration"
    get "registration/change_password(.:format)" => "public#change_password", cell: "nodes/registration"
    post "registration/change_password(.:format)" => "public#change_password", cell: "nodes/registration"
    get "registration/confirm_password(.:format)" => "public#confirm_password", cell: "nodes/registration"
    post "registration/postal_code(.:format)" => "public#postal_code", cell: "nodes/registration"
  end

  page "member" do
    get "blog_page/:filename.:format" => "public#index", cell: "pages/blog_page"

    get "photo/:filename.:format" => "public#index", cell: "pages/photo"
    get "photo_spot/:filename.:format" => "public#index", cell: "pages/photo_spot"
  end

  part "member" do
    get "login" => "public#index", cell: "parts/login"
    get "blog_page" => "public#index", cell: "parts/blog_page"
    get "photo" => "public#index", cell: "parts/photo"
    get "photo_slide" => "public#index", cell: "parts/photo_slide"
    get "photo_search" => "public#index", cell: "parts/photo_search"
    get "invited_group" => "public#index", cell: "parts/invited_group"
  end

  namespace "member", path: ".m:member", member: /\d+/ do
    namespace "apis" do
      resources :temp_files, concerns: :deletion do
        get :select, on: :member
        get :view, on: :member
        get :thumb, on: :member
        get :download, on: :member
      end
    end
  end

  namespace "member", path: ".s:site/member", module: "member" do
    namespace "apis" do
      resources :photos, concerns: :deletion do
        get :select, on: :member
      end
    end

    resources :groups, concerns: :deletion do
      resources :members, controller: :group_members, concerns: :deletion
    end
  end
end
