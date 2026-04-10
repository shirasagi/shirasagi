class Cms::Apis::LoopSettingsController < ApplicationController
  include Cms::ApiFilter

  model Cms::LoopSetting

  def show
    @item = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      where(id: params[:id]).first
    raise '404' if @item.blank?

    render json: { html: @item.html }
  end
end
