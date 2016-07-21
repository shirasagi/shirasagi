class Sns::UserProfilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter

  skip_action_callback :require_self, except: [:index]

  model SS::User

  menu_view nil

  private
    def set_crumbs
      @crumbs << [:"sns.profile", params.include?(:user) ? sns_user_profile_path : sns_cur_user_profile_path]
    end

    def set_item
      @item = @sns_user
    end

  public
    def show
      render
    end

    #def new, create, edit, update, destroy;
    #  raise '404'
    #end
end
