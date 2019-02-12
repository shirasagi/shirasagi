class Cms::Apis::Preview::NodesController < ApplicationController
  include Cms::ApiFilter

  model Cms::Node

  before_action :set_item, only: [:publish]

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def publish
    raise "403" if !@item.allowed?(:edit, @cur_user, site: @cur_site)

    if @item.try(:release_date).present?
      @item.state = "ready"
    else
      @item.state = "public"
    end
    result = @item.save

    if !result
      render json: @item.errors.full_messages, status: :unprocessable_entity
      return
    end

    render json: { reload: true }, status: :ok
  end
end
