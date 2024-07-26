class Gws::Apis::UserDetailController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  before_action :set_item

  private

  def set_item
    @item = @model.site(@cur_site).find(params[:id]) rescue nil
    raise "404" if @item.nil?
  end

  public

  def index
  end
end
