class Inquiry::SiteAnswersController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  include Inquiry::AnswersFilter

  navi_view "cms/main/navi"
  menu_view "inquiry/answers/menu"

  before_action :check_permission

  private

  def fix_params
    { cur_site: @cur_site }
  end

  def check_permission
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_items
    @state = params.dig(:s, :state).presence || "unclosed"

    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      search(params[:s]).
      state(@state)
  end
end
