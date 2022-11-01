module Gws::Workload::WorkFilter
  extend ActiveSupport::Concern

  included do
    attr_accessor(:cur_tab)
    append_view_path 'app/views/gws/workload/main'

    model Gws::Workload::Work

    before_action :set_cur_tab
    before_action :set_crumbs
    before_action :set_item, only: %i[show edit update disable delete destroy set_seen unset_seen active recover]
    before_action :set_selected_items, only: %i[active_all disable_all destroy_all set_seen_all unset_seen_all download_all]
    before_action :set_category
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site}
  end

  def pre_params
    set_year
    set_category
    ret = { due_date: Time.zone.now + @cur_site.workload_default_due_date.day }
    ret[:year] = @year if @year
    ret[:category_ids] = [@category.id] if @category
    ret
  end

  # must be overridden by sub-class
  def set_cur_tab
  end

  def set_crumbs
    set_category
    @crumbs << [@cur_site.menu_workload_label || I18n.t('modules.gws/workload'), gws_workload_main_path]
    @crumbs << @cur_tab if @cur_tab
    if @category.present?
      @crumbs << [@category.name, { action: :index, category: @category }]
    end
  end

  def set_category
    @categories ||= Gws::Workload::Category.site(@cur_site)
    if category_id = params[:category].presence
      @category ||= Gws::Workload::Category.site(@cur_site).where(id: category_id).first
    end
  end

  # def render_destroy_all(result)
  #   location = crud_redirect_url || { action: :index }
  #   notice = result ? { notice: t('gws/workload.notice.disable') } : {}
  #   errors = @items.map { |item| [item.id, item.errors.full_messages] }
  #
  #   respond_to do |format|
  #     format.html { redirect_to location, notice }
  #     format.json { head json: errors }
  #   end
  # end

  public

  def index
    params[:s] ||= {}
    params[:s][:site] = @cur_site
    params[:s][:year] = @year if @year.present?
    params[:s][:category_id] = @category.id if @category.present?

    set_items
  end

  def create
    @item = @model.new get_params
    if params[:commit] == t("ss.buttons.draft_save")
      @item.state = 'draft'
    elsif params[:commit] == t("ss.buttons.publish_save")
      @item.state = 'public'
    end
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_create @item.save
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    if params[:commit] == t("ss.buttons.draft_save")
      @item.state = 'draft'
    elsif params[:commit] == t("ss.buttons.publish_save")
      @item.state = 'public'
    end
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    render_update @item.update
  end

  def download_all
    raise '403' if @items.empty?

    csv = @items.
      reorder(updated: -1).
      to_csv.
      encode('SJIS', invalid: :replace, undef: :replace)

    send_data csv, filename: "workload_#{Time.zone.now.to_i}.csv"
  end
end
