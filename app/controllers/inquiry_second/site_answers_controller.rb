class InquirySecond::SiteAnswersController < ApplicationController
  include Cms::BaseFilter
  include SS::CrudFilter
  include InquirySecond::AnswersFilter

  navi_view "cms/main/navi"
  menu_view "inquiry_second/answers/menu"

  before_action :check_permission
  before_action :set_inquiry_second_form

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.inquiry_second/answer"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site, cur_node: @cur_inquiry_second_form }
  end

  def check_permission
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_inquiry_second_form
    @cur_inquiry_second_form ||= begin
      node = @cur_site.inquiry_second_form
      raise "404" if node.blank?
      node
    end
  end

  def set_items
    set_inquiry_second_form
    @state = params.dig(:s, :state).presence || "unclosed"

    @items = @model.site(@cur_site).
      allow(:read, @cur_user).
      where(node_id: @cur_inquiry_second_form.id).
      search(params[:s]).
      state(@state)
  end
end
