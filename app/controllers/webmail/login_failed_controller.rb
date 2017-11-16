class Webmail::LoginFailedController < ApplicationController
  include Webmail::BaseFilter
  include SS::CrudFilter

  model SS::User

  def index
    #
  end
end
