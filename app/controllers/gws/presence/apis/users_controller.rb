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

  def states
    @item = Gws::UserPresence.new
    @items = []

    @item.state_options.each_with_index do |state, order|
      @items << [state[1], state[0], @item.state_style(state[1]), order]
    end
  end
end
