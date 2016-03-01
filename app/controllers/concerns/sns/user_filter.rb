module Sns::UserFilter
  extend ActiveSupport::Concern
  include Sns::BaseFilter

  included do
    before_action :set_sns_user
    before_action :require_self
    before_action :set_crumbs
    navi_view "sns/user/main/navi"
  end

  private
    def set_sns_user
      if params.include?(:user)
        @sns_user = SS::User.find params[:user]
        @crumbs <<  [@sns_user.name, sns_user_profile_path(@sns_user)]
      else
        @sns_user = @cur_user
        @crumbs <<  [@sns_user.name, sns_cur_user_profile_path]
      end
    end

    def require_self
      raise "403" if @cur_user.id != @sns_user.id
    end
end
