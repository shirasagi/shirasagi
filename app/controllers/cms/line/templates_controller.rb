class Cms::Line::TemplatesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/line/main/navi"

  before_action :set_message
  before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  before_action :redirect_to_select_type, only: [:new]

  private

  def set_crumbs
    set_message
    @crumbs << [t("cms.line_message"), cms_line_messages_path]
    @crumbs << [@message.name, cms_line_message_path(id: @message)]
  end

  def redirect_to_select_type
    return if @type.present?
    redirect_to({ action: :select_type })
  end

  def set_message
    @message ||= Cms::Line::Message.find(params[:message_id])
    @addon_basic_name = "テンプレート"
  end

  def set_model
    @type = params[:type].presence
    @type = nil if @type == "-"
    @model = @type ? "#{Cms::Line::Template}::#{@type.classify}".constantize : Cms::Line::Template::Base
  end

  def set_item
    super
    @type = @item.type
  end

  def pre_params
    { message: @message }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, message: @message, order: order }
  end

  def crud_redirect_url
    @message.private_show_path
  end

  def order
    return @item.order if @item && @item.persisted?
    last_one = @message.templates.order_by(order: 1).to_a.last
    last_one ? (last_one.order + 1) : 0
  end

  public

  def select_type
  end
end
