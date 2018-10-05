class Webmail::LoginFailedController < ApplicationController
  include Webmail::BaseFilter
  include SS::CrudFilter

  skip_before_action :imap_initialize

  model SS::User

  def index
    #
  end
end
