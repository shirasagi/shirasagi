class Gws::Presence::Apis::CustomGroup::UsersController < ApplicationController
  include Gws::ApiFilter
  include Gws::BaseFilter
  include Gws::Presence::Users::ApiFilter

  private

  def set_groups
    @group = Gws::CustomGroup.find(params[:group]) rescue nil

    raise "404" unless @group
    raise "404" unless @group.member_ids.include?(@cur_user.id)

    @groups = [@group]
  end

  def set_user
    @user = @group.members.and(id: params[:id]).first
  end

  public

  def index
    raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)

    @items = @group.members
    if params[:limit]
      @items = @items.page(params[:page].to_i).per(params[:limit])
    end
  end
end
