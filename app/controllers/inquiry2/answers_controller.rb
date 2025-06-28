class Inquiry2::AnswersController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  include Inquiry2::AnswersFilter

  navi_view "inquiry2/main/navi"

  before_action :check_permission

  private

  def fix_params
    { cur_site: @cur_site, cur_node: @cur_node }
  end

  def check_permission
    raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_items
    @state = params.dig(:s, :state).presence || "unclosed"

    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      where(node_id: @cur_node.id).
      search(params[:s]).
      state(@state)
  end
end
