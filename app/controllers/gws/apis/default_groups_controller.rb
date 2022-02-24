class Gws::Apis::DefaultGroupsController < ApplicationController
  include Gws::BaseFilter

  def update
    result = @cur_user.set_gws_default_group_id(params[:default_group].to_s)
    if result
      render json: { status: "ok" }, status: :ok
    else
      render json: { status: "error", errors: @cur_user.errors.full_messages }, status: :bad_request
    end
  end
end
