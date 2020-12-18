class Gws::Board::TopicsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Board::BaseFilter
  include Gws::Memo::NotificationFilter

  model Gws::Board::Topic

  navi_view "gws/board/main/navi"

  self.destroy_notification_actions = [:soft_delete]
  self.destroy_all_notification_actions = [:soft_delete_all]

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
    base_criteria = @model.site(@cur_site).topic
    if @mode == 'editable'
      base_criteria.allow(:read, @cur_user, site: @cur_site).without_deleted
    elsif @mode == 'trash'
      base_criteria.allow(:trash, @cur_user, site: @cur_site).only_deleted
    else
      conditions = @model.member_conditions(@cur_user)
      conditions += @model.readable_conditions(@cur_user, site: @cur_site)
      conditions << @model.allow_condition(:read, @cur_user, site: @cur_site)
      base_criteria.and_public.without_deleted.where("$and" => [{ "$or" => conditions }])
    end
  end

  def readable?
    if @mode == 'editable'
      @item.allowed?(:read, @cur_user, site: @cur_site) && @item.deleted.blank?
    elsif @mode == 'trash'
      @item.allowed?(:trash, @cur_user, site: @cur_site) && @item.deleted.present?
    else
      return false if @item.deleted.present?

      return true if @item.allowed?(:read, @cur_user, site: @cur_site)
      return true if @item.readable?(@cur_user, site: @cur_site)
      return true if @item.member?(@cur_user)

      false
    end
  end

  public

  def index
    if @category.present?
      params[:s] ||= {}
      params[:s][:site] = @cur_site
      params[:s][:category] = @category.name
    end

    if params[:s]
      params[:s][:user] = @cur_user
    end

    @items = items.search(params[:s]).
      order(descendants_updated: -1).
      page(params[:page]).per(50)
  end

  def show
    raise '403' unless readable?

    render file: "show_#{@item.mode}"
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
        format.html { render({ file: :edit }) }
        format.json { render(json: @item.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type) }
      end
    end
  end

  def print
    set_item
    raise '403' unless readable?

    render file: "print_#{@item.mode}", layout: 'ss/print'
  end

  def soft_delete
    set_item unless @item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.notification_noticed_at = nil
    @item.deleted = Time.zone.now
    render_destroy @item.save
  end

  def undo_delete
    set_item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get?
      render
      return
    end

    @item.notification_noticed_at = nil
    @item.deleted = nil

    render_opts = {}
    render_opts[:location] = gws_board_topics_path(mode: 'editable')
    render_opts[:render] = { file: :undo_delete }
    render_opts[:notice] = t('ss.notice.restored')

    render_update @item.save, render_opts
  end
end
