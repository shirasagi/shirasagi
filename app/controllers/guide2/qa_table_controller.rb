class Guide2::QaTableController < ApplicationController
  include Cms::BaseFilter
  include Cms::NodeFilter

  model Guide2::Node::Question

  layout "guide2/form_qa"
  navi_view "cms/node/main/navi"
  #menu_view "cms/crud/resources_menu"

  before_action :set_question_model
  before_action :set_addons

  private

  def set_crumbs
    @crumbs << [t("guide2.qa_table"), action: :index]
  end

  def set_question_model
    # @question_model = Guidance::Question
    # @model ||= @question_model
  end

  def set_addons
    # @addons = [Guidance::Addon::QuestionNode.addon_name]
    # @show_guidance_question_node_addon = true
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
    @items = []
    @item = @cur_node
    #raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  def update
    @item = @cur_node

    permitted_params = params.permit(
      results: Guide2::Result.table_fields + [:id, conditions: [:_id, :value]],
      questions: Guide2::Question.table_fields + [:id],
    )

    results = permitted_params[:results].to_h.map do |_, item|
      # Guide2::Result.new(item)
      #item[:conditions] = []
      item[:name].present? ? item : nil
    end
    @item.guide2_results = results.compact

    questions = permitted_params[:questions].to_h.map do |_, item|
      # Guide2::Question.new(item)
      item[:name].present? ? item : nil
    end
    @item.guide2_questions = questions.compact

    # custom = params.require(:custom)
    # new_column_values = @cur_form.build_column_values(custom)
    # @item.update_column_values(new_column_values)

    #results.map { |c| dump c.attributes }
    #questions.map { |c| dump c.attributes }
    #@item.results.map { |c| dump c.attributes }
    #@item.questions.map { |c| dump c.attributes }

    @item.save # reload hash

    return redirect_to action: :index
  end

  def show
    #raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  # def download
  #   set_item
  #   #raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)

  #   filename = @item.name + "_" + t("mongoid.models.guide2/question")
  #   send_enum @item.guide_question_list.enum_csv, filename: "#{filename}.csv"
  # end

  # def import
  #   set_item
  #   raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

  #   @item = @question_model.new
  #   return if request.get? || request.head?

  #   @item.attributes = get_params
  #   result = @item.import_csv(@cur_node)
  #   flash.now[:notice] = t("ss.notice.saved") if result
  #   render_create result, location: { action: :show }, render: { template: "import" }
  # end
end
