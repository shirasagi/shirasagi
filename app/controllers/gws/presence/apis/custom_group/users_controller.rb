class Gws::Presence::Apis::CustomGroup::UsersController < ApplicationController
  include Gws::ApiFilter
  include Gws::BaseFilter
  include Gws::Presence::Users::ApiFilter

  private

  def set_groups
    @group = Gws::CustomGroup.find(params[:group]) rescue nil

    raise "404" unless @group
    raise "404" unless @group.readable?(@cur_user)

    @groups = [@group]
  end

  def set_user
    @user = @group.members.active.and(id: params[:id]).first
  end

  public

  def index
    raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)

    @items = @group.members.active.order_by_title(@cur_site)
    if params[:limit]
      @items = @items.page(params[:page].to_i).per(params[:limit])
    end
  end
end
