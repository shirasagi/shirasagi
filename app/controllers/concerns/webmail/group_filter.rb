module Webmail::GroupFilter
  extend ActiveSupport::Concern

  included do
    navi_view "webmail/main/group_navi"
  end

  private

  def imap_initialize
    @imap_setting = @cur_user.groups.find_by(id: params[:group]).imap_setting

    if @imap_setting
      @redirect_path = webmail_group_login_failed_path(group: params[:group])
    else
      @redirect_path = sys_group_path(id: params[:group])
    end

    @imap = Webmail::Imap::Base.new(@cur_user, @imap_setting)
  end
end
