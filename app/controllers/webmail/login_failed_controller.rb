class Webmail::LoginFailedController < ApplicationController
  include Webmail::BaseFilter
  include SS::CrudFilter

  model SS::User

  #menu_view "ss/crud/resource_menu"

  def index
    #
  end
end
