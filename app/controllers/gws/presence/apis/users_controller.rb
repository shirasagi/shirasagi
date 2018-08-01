class Gws::Presence::Apis::UsersController < ApplicationController
  include Gws::ApiFilter
  include Gws::BaseFilter
  include Gws::Presence::Users::ApiFilter

  def index
    raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)

    @items = @model.in(group_ids: @groups.pluck(:id))
    if params[:limit]
      @items = @items.page(params[:page].to_i).per(params[:limit])
    end
  end
end
