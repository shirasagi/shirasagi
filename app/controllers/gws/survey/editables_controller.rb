class Gws::Survey::EditablesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  before_action :set_categories
  before_action :set_category
  before_action :set_search_params
  before_action :set_items
  before_action :set_item, only: [:show, :edit, :update, :soft_delete, :move, :publish, :depublish, :copy, :print, :preview]
  before_action :respond_404_if_item_is_public, only: [:edit, :update, :soft_delete, :move]
  before_action :set_selected_items, only: [:destroy_all, :soft_delete_all]

  model Gws::Survey::Form

  navi_view "gws/survey/main/navi"

  private

  # override SS::CrudFilter#prepend_current_view_path
  def prepend_current_view_path
    if params[:action] == "preview"
      prepend_view_path 'app/views/gws/survey/files'
    else
      super
    end
  end

  # override Gws::CrudFilter#append_view_paths
  def append_view_paths
    append_view_path "app/views/gws/survey/main"
    super
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_survey_label || t('modules.gws/survey'), gws_survey_main_path]
    @crumbs << [t('ss.navi.editable'), action: :index, folder_id: '-', category_id: '-']
  end

  def permit_fields
    fields = super
    if params[:action] == "create"
      fields += %i[anonymous_state file_state]
    end
    fields
  end

  def pre_params
    { due_date: Time.zone.now.beginning_of_hour + 1.hour + @cur_site.survey_default_due_date.day }
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_categories
    @categories ||= Gws::Survey::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def set_category
    return if params[:category_id].blank? || params[:category_id] == '-'
    @category ||= @categories.find(params[:category_id])
    raise '403' unless @category.readable?(@cur_user) || @category.allowed?(:read, @cur_user, site: @cur_site)
  end

  def set_search_params
    @s = OpenStruct.new(params[:s])
    if @folder.present?
      @s[:folder_ids] = [ @folder.id ]
      @s[:folder_ids] += @folder.folders.for_post_editor(@cur_site, @cur_user).pluck(:id)
    end

    @s[:category_id] = @category.id if @category.present?
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site).
      without_deleted.
      search(@s)
  end

  def set_item
    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def respond_404_if_item_is_public
    raise "404" if @item.public?
  end

  public

  def index
    @categories = @categories.tree_sort
    @items = @items.order_by(updated: -1, id: 1).page(params[:page]).per(50)
  end

  def create
    @item = @model.new get_params
    return render_create(false) unless @item.allowed?(:edit, @cur_user, site: @cur_site, strict: true)

    result = @item.save

    create_opts = {}
    create_opts[:location] = gws_survey_editable_columns_path(editable_id: @item) if result
    render_create result, create_opts
  end

  def publish
    if @item.state == "public"
      redirect_to({ action: :show }, { notice: t('ss.notice.published') })
      return
    end
    return if request.get? || request.head?

    @item.attributes = get_params
    @item.state = 'public'
    render_opts = { render: { template: "publish" }, notice: t('ss.notice.published') }
    render_update @item.save, render_opts
  end

  def depublish
    if @item.state != "public"
      redirect_to({ action: :show }, { notice: t('ss.notice.depublished') })
      return
    end
    return if request.get? || request.head?

    @item.state = 'closed'
    render_opts = { render: { template: "depublish" }, notice: t('ss.notice.depublished') }
    render_update @item.save, render_opts
  end

  def copy
    raise "404" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      @item.name = "[#{I18n.t("workflow.cloned_name_prefix")}] #{@item.name}"
      render
      return
    end

    service = Gws::Column::CopyService.new(cur_site: @cur_site, cur_user: @cur_user, model: @model, item: @item)
    service_params = params.require(:item).permit(:name, :anonymous_state, :file_state)
    service_params[:state] = "closed"
    service_params[:answered_users_hash] = {}
    service_params[:notification_noticed_at] = nil
    service.overwrites = service_params
    result = service.call
    if result
      @item = service.new_item
    else
      SS::Model.copy_errors(service, @item)
    end
    render_create result, render: { template: "copy" }, notice: t("ss.notice.copied")
  end

  def print
    @cur_form = @item
    @item = Gws::Survey::File.new
    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    @item.cur_form = @cur_form
    @item.name = t("gws/survey.file_name", form: @cur_form.name)

    @back = { action: :show }
    render layout: 'ss/print'
  end

  def preview
    @cur_form = @item
    @item = Gws::Survey::File.new
    @item.cur_site = @cur_site
    @item.cur_user = @cur_user
    @item.cur_form = @cur_form
    @item.name = t("gws/survey.file_name", form: @cur_form.name)

    render_opts = { template: "gws/survey/files/edit", locals: { preview: true } }
    render_opts[:layout] = false if request.xhr?
    render render_opts
  end
end
