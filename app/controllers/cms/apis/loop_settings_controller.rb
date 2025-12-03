class Cms::Apis::LoopSettingsController < ApplicationController
  include Cms::ApiFilter

  before_action :set_item

  def show
    render json: {
      id: @item.id,
      name: @item.name,
      html: @item.html.to_s
    }
  end

  private

  def set_item
    @item = Cms::LoopSetting.site(@cur_site).find(params[:id])
    raise "404" unless @item
    # stateが"public"またはnil/blankの場合のみ許可
    unless @item.state == "public" || @item.state.blank?
      raise "403"
    end
  rescue Mongoid::Errors::DocumentNotFound
    raise "404"
  end
end
