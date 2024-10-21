class Sns::LoginImageController < ApplicationController
  include HttpAcceptLanguage::AutoLocale
  include Sns::BaseFilter

  skip_before_action :logged_in?

  layout "ss/login"

  def index
    @hide_ss_layout_header = true

    respond_to do |format|
      format.html { render }
      format.json  do
        @model = Sys::Setting
        @item = @model.first
        @url = ::File.dirname(sns_mypage_url)
      end
    end
  end
end
