class Gws::Workflow2::Apis::UserSuperiorsController < ApplicationController
  include Gws::ApiFilter

  model Gws::User

  def show
    item = Gws::User.site(@cur_site).find(params[:id]) rescue nil
    raise "404" unless item

    users = item.gws_superior_users(@cur_site)
    @item = Gws::User.order_users_by_title(users, cur_site: @cur_site).first
    raise "404" unless @item
  end
end
