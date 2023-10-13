class Sns::LoginImageController < ApplicationController
  include HttpAcceptLanguage::AutoLocale
  include Sns::BaseFilter

  skip_before_action :logged_in?

  layout "ss/login"

  def index
    @hide_ss_layout_header = true
  end
end
