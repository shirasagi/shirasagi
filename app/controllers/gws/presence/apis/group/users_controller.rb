class Gws::Presence::Apis::Group::UsersController < ApplicationController
  include Gws::ApiFilter
  include Gws::BaseFilter
  include Gws::Presence::Users::ApiFilter

  private

  def set_groups
    @group = Gws::Group.find(params[:group]) rescue nil
    raise "404" unless @group

    @groups = [ @cur_site.root ] + @cur_site.root.descendants.active.to_a
    raise "404" unless @groups.select { |group| group.id == @group.id }

    @groups = [@group]
  end

  def set_user
    @user = @group.users.active.and(id: params[:id]).first
  end

  public

  def index
    raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)

    @items = @group.users.active.order_by_title(@cur_site)
    if params[:limit]
      @items = @items.page(params[:page].to_i).per(params[:limit])
    end
  end
end
