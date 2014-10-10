module Sns::UserFilter
  extend ActiveSupport::Concern
  include Sns::BaseFilter

  included do
    before_action :set_sns_user #, if: ->{ request.env["REQUEST_PATH"] =~ /^\/\.u\d+\// }
    before_action :set_crumbs
    navi_view "sns/user/main/navi"
  end

  private
    def set_sns_user
      uid = request.env["REQUEST_PATH"].sub(/^\/\.u(\d+)\/.*/, '\\1')
      @sns_user = SS::User.find uid
      @crumbs <<  [@sns_user.name, sns_user_path(@sns_user)]
    end

    def require_self
      raise "403" if @cur_user.id != @sns_user.id
    end
end
