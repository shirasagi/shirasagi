class Guidance::QuestionsController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  navi_view "cms/node/main/navi"
  menu_view "cms/crud/resource_menu"

  before_action :set_question_model
  before_action :set_addons

  private

  def set_crumbs
    @crumbs << [t("mongoid.models.guidance/question"), action: :show]
  end

  def set_question_model
    @question_model = Guidance::Question
    @model ||= @question_model
  end

  def set_addons
    @addons = [Guidance::Addon::QuestionNode.addon_name]
    @show_guidance_question_node_addon = true
  end

  def set_item
    @item = @cur_node
    @item.attributes = fix_params
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  public

  def index
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  def download
    set_item
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    filename = @item.name + "_" + t("mongoid.models.guidance/question")
    send_enum @item.guidance_question_list.enum_csv, filename: "#{filename}.csv"
  end

  def import
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item = @question_model.new
    return if request.get? || request.head?

    @item.attributes = get_params
    result = @item.import_csv(@cur_node)
    flash.now[:notice] = t("ss.notice.saved") if result
    render_create result, location: { action: :show }, render: { template: "import" }
  end
end
