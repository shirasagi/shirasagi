class Gws::Monitor::AdminsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Monitor::Topic

  before_action :set_item, only: [
    :show, :edit, :update, :delete, :destroy,
    :public, :preparation, :question_not_applicable, :answered, :disable
  ]

  before_action :set_selected_items, only: [
      :destroy_all, :public_all,
      :preparation_all, :question_not_applicable_all, :disable_all
  ]

  before_action :set_category

  private

  def set_crumbs
    set_category
    if @category.present?
      @crumbs << [t("modules.gws/monitor"), gws_monitor_admins_path]
      @crumbs << [@category.name, action: :index]
    else
      @crumbs << [t("modules.gws/monitor"), action: :index]
    end
  end

  def set_category
    @categories = Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).tree_sort
    if category_id = params[:category].presence
      @category ||= Gws::Monitor::Category.site(@cur_site).readable(@cur_user, @cur_site).where(id: category_id).first
    end
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    current_category_id = super
    if @category.present?
      current_category_id[:category_ids] = [ @category.id ]
    end
    current_category_id
  end

  public

  def index
    @items = @model.site(@cur_site).topic

    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    if @cur_user.gws_role_permissions["read_other_gws_monitor_posts_#{@cur_site.id}"] &&
        @cur_user.gws_role_permissions["delete_other_gws_monitor_posts_#{@cur_site.id}"]
      @items = @items.search(params[:s]).
          custom_order(params.dig(:s, :sort) || 'updated_desc').
          page(params[:page]).per(50)
    else
      @items = @items.search(params[:s]).
          and_admins(@cur_user).
          custom_order(params.dig(:s, :sort) || 'updated_desc').
          page(params[:page]).per(50)
    end
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render file: "/gws/monitor/main/show_#{@item.mode}"
  end

  def create
    @item = @model.new get_params

    @item.attributes["readable_group_ids"] = (@item.attend_group_ids + @item.readable_group_ids).uniq

    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
    render_create @item.save
  end

  def read
    set_item
    raise '403' unless @item.readable?(@cur_user)

    result = true
    if !@item.browsed?(@cur_user)
      @item.set_browsed(@cur_user)
      @item.record_timestamps = false
      result = @item.save
    end

    if result
      respond_to do |format|
        format.html { redirect_to({ action: :show }, { notice: t('ss.notice.saved') }) }
        format.json { render json: { _id: @item.id, browsed_at: @item.browsed_at(@cur_user) }, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { render({ file: :edit }) }
        format.json { render(json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type) }
      end
    end
  end

  def public
    raise '403' unless @item.readable?(@cur_user, @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "public")
    @item.save
    render_update@item.update
  end

  def preparation
    raise '403' unless @item.readable?(@cur_user, @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "preparation")
    @item.save
    render_update@item.update
  end

  def question_not_applicable
    raise '403' unless @item.readable?(@cur_user, @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "question_not_applicable")
    @item.save
    render_update@item.update
  end

  def answered
    raise '403' unless @item.readable?(@cur_user, @cur_site)
    @item.state_of_the_answers_hash.update(@cur_group.id.to_s => "answered")
    @item.save
    render_update@item.update
  end

  def disable
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.disable, {notice: t('gws/monitor.notice.disable')}
  end

  def render_destroy_all(result)
    location = crud_redirect_url || { action: :index }
    notice = result ? { notice: t("gws/monitor.notice.disable") } : {}
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    respond_to do |format|
      format.html { redirect_to location, notice }
      format.json { head json: errors }
    end
  end

  def public_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "public")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def preparation_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "preparation")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def question_not_applicable_all
    entries = @items.entries
    @items = []

    entries.each do |item|
      if item.readable?(@cur_user, @cur_site)
        item.state_of_the_answers_hash.update(@cur_group.id.to_s => "question_not_applicable")
        item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end
end

