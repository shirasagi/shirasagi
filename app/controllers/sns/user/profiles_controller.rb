class Sns::User::ProfilesController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter

  before_action :require_self, except: [:show]

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
