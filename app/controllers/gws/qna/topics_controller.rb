class Gws::Qna::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Qna::BaseFilter
  include Gws::Memo::NotificationFilter

  model Gws::Qna::Topic

  navi_view "gws/qna/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    p = super
    p[:category_ids] = [@category.id] if @category.present?
    p
  end

  def items
    if @mode == 'editable'
      @model.site(@cur_site).topic.allow(:read, @cur_user, site: @cur_site).without_deleted
    elsif @mode == 'trash'
      @model.site(@cur_site).topic.allow(:trash, @cur_user, site: @cur_site).only_deleted
    else
      @model.site(@cur_site).topic.and_public.readable(@cur_user, site: @cur_site).without_deleted
    end
  end

  def readable?
    if @mode == 'editable'
      @item.allowed?(:read, @cur_user, site: @cur_site) && @item.deleted.blank?
    elsif @mode == 'trash'
      @item.allowed?(:trash, @cur_user, site: @cur_site) && @item.deleted.present?
    else
      (@item.allowed?(:read, @cur_user, site: @cur_site) || @item.readable?(@cur_user)) && @item.deleted.blank?
    end
  end

  public

  def index
    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    params[:s] ||= {}
    params[:s][:user] = @cur_user
    params[:s][:browsed_state] = 'both' if params[:s][:browsed_state].blank?

    @items = items.search(params[:s]).
      custom_order(params.dig(:s, :sort) || 'updated_desc').
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless readable?
    render template: "show_#{@item.mode}"
  end

  def read
    set_item
    raise '403' unless readable?

    result = true
    if !@item.browsed?(@cur_user)
      @item.set_browsed!(@cur_user)
      result = true
      @item.reload
    end

    if result
      respond_to do |format|
        format.html { redirect_to({ action: :show }, { notice: t('ss.notice.saved') }) }
        format.json { render json: { _id: @item.id, browsed_at: @item.browsed_at(@cur_user) }, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { render({ template: "edit" }) }
        format.json { render(json: @item.errors.full_messages, status: :unprocessable_content, content_type: json_content_type) }
      end
    end
  end

  def unread
    set_item
    raise '403' unless readable?

    @item.unset_browsed!(@cur_user) if @item.browsed?(@cur_user)

    respond_to do |format|
      format.html { redirect_to({ action: :show, toggled: 1 }, { notice: t('ss.notice.saved') }) }
      format.json { render json: { _id: @item.id }, content_type: json_content_type }
    end
  end

  def set_browsed_all
    @items = items.in(id: params[:ids])
    @items.each do |item|
      item.set_browsed!(@cur_user) unless item.browsed?(@cur_user)
    end
    render_confirmed_all(true, notice: t("ss.notice.set_seen_all"))
  end

  def unset_browsed_all
    @items = items.in(id: params[:ids])
    @items.each do |item|
      item.unset_browsed!(@cur_user) if item.browsed?(@cur_user)
    end
    render_confirmed_all(true, notice: t("ss.notice.unset_seen_all"))
  end

  def resolve
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.update(question_state: 'resolved')
    redirect_to action: :show
  end

  def unresolve
    set_item
    raise '403' unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    @item.update(question_state: 'open')
    redirect_to action: :show
  end
end
