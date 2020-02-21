class Recommend::History::ReceiverController < ApplicationController
  include Recommend::ReceiverFilter

  before_action :set_site

  private

  def set_site
    @cur_site = Cms::Site.find id: params[:site]
  end
end
