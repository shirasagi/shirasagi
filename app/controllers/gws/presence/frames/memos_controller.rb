class Gws::Presence::Frames::MemosController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Presence::Users::AuthFilter

  model Gws::UserPresence

  layout "ss/item_frame"

  before_action :set_frame_id
  before_action :set_item

  private

  def set_frame_id
    @frame_id = params[:frame_id]
  end

  def set_item
    @user = Gws::User.find(params[:id])
    @item = @user.user_presence(@cur_site)
    @item.cur_site = @cur_site
    @item.cur_user = @user
  end

  public

  def show
    raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)
  end

  def edit
    raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)
  end

  def update
    raise "403" unless editable_user?(@user)
    @item.attributes = get_params
    @item.update
    render :update
  end
end
