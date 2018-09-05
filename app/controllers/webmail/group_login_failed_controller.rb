class Webmail::GroupLoginFailedController < Webmail::LoginFailedController
  include Webmail::GroupFilter
  menu_view "webmail/login_failed/menu"

  model SS::Group

  def index; end
end
