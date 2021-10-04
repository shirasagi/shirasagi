module Gws::Circular::PostFilter
  extend ActiveSupport::Concern

  included do
    append_view_path 'app/views/gws/circular/main'
    attr_accessor(:cur_tab)

    model Gws::Circular::Post

    before_action :set_cur_tab
    before_action :set_crumbs
    before_action :set_item, only: %i[show edit update disable delete destroy set_seen unset_seen active recover]
    before_action :set_selected_items, only: %i[active_all disable_all destroy_all set_seen_all unset_seen_all download_all]
    before_action :set_category
  end

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    set_category
    ret = { due_date: Time.zone.now + @cur_site.circular_default_due_date.day }
    ret[:category_ids] = [@category.id] if @category
    ret
  end

  # must be overridden by sub-class
  def set_cur_tab
  end

  def set_crumbs
    set_category
    @crumbs << [@cur_site.menu_circular_label || I18n.t('modules.gws/circular'), gws_circular_main_path]
    @crumbs << @cur_tab if @cur_tab
    if @category.present?
      @crumbs << [@category.name, { action: :index, category: @category }]
    end
  end

  def set_category
    @categories ||= Gws::Circular::Category.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Circular::Category.site(@cur_site).readable(@cur_user, site: @cur_site).where(id: category_id).first
    end
  end

  # def render_destroy_all(result)
  #   location = crud_redirect_url || { action: :index }
  #   notice = result ? { notice: t('gws/circular.notice.disable') } : {}
  #   errors = @items.map { |item| [item.id, item.errors.full_messages] }
  #
  #   respond_to do |format|
  #     format.html { redirect_to location, notice }
  #     format.json { head json: errors }
  #   end
  # end

  public

  def index
    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category_id] = @category.id
    end
    if params.dig(:s, :article_state).present?
      params[:s][:user] = @cur_user
    end

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

    send_data csv, filename: "circular_#{Time.zone.now.to_i}.csv"
  end

  def set_seen
    raise '404' if !@item.public? || !@item.active?
    raise '403' unless @item.member?(@cur_user)

    render_update @item.set_seen(@cur_user).save, notice: t("ss.notice.set_seen")
  end

  def unset_seen
    raise '404' if !@item.public? || !@item.active?
    raise '403' unless @item.member?(@cur_user)

    render_update @item.unset_seen(@cur_user).save, notice: t("ss.notice.unset_seen")
  end

  def set_seen_all
    @items.each do |item|
      if item.unseen?(@cur_user)
        item.attributes = fix_params
        item.set_seen(@cur_user).save
      end
    end
    render_destroy_all(true, notice: t("ss.notice.set_seen"))
  end

  def unset_seen_all
    @items.each do |item|
      if item.seen?(@cur_user)
        item.attributes = fix_params
        item.unset_seen(@cur_user).save
      end
    end
    render_destroy_all(true, notice: t("ss.notice.unset_seen"))
  end
end
