class Cms::Line::DeliverPlansController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Cms::Line::DeliverPlan

  navi_view "cms/line/main/navi"

  before_action :set_message

  private

  def set_crumbs
    set_message
    @crumbs << [t("cms.line_message"), cms_line_messages_path]
    @crumbs << [@message.name, cms_line_message_path(id: @message)]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, message: @message, in_ready: true }
  end

  def set_message
    @message ||= Cms::Line::Message.site(@cur_site).find(params[:message_id])
  end

  def set_items
    @items = @message.deliver_plans
  end

  def crud_redirect_url
    { action: :index }
  end
end
