class Sns::UserProfilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter

  skip_action_callback :require_self, except: [:index]

  model SS::User

  menu_view nil

  private
    def set_crumbs
      @crumbs << [:"sns.profile", sns_user_profile_path]
    end

    def set_item
      @item = @sns_user
    end
end
