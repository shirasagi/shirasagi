class Gws::DefaultGroupsController < ApplicationController
  include Gws::BaseFilter

  def update
    @cur_user.set_gws_default_group_id(params[:default_group].to_s)
    redirect_to gws_portal_path
  end
end
