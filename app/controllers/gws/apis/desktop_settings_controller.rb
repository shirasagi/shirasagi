class Gws::Apis::DesktopSettingsController < ApplicationController
  include Gws::ApiFilter

  def index
    render json: @cur_site.desktop_settings
  end
end
