module Gws::Schedule::TodoFilter
  extend ActiveSupport::Concern
  include Gws::Schedule::CalendarFilter::Transition

  included do
    cattr_accessor :default_todo_state
    cattr_accessor :default_groupings
    self.default_groupings = "none"
    append_view_path 'app/views/gws/schedule/todo/main'
    helper Gws::Schedule::TodoHelper
    model Gws::Schedule::Todo

    navi_view "gws/schedule/todo/main/navi"
    menu_view "gws/schedule/todo/main/menu"

    before_action :set_category
    before_action :set_search_params
    before_action :set_item, only: %i[show edit update delete destroy disable popup finish revert recover active soft_delete]
    before_action :set_selected_items, only: [:destroy_all, :soft_delete_all, :finish_all, :revert_all, :active_all]
    before_action :set_skip_default_group
  end

  private

  def set_category
    if params.key?(:category)
      case params[:category].to_s
      when Gws::Schedule::TodoCategory::ALL.id
        @cur_category = Gws::Schedule::TodoCategory::ALL
      when Gws::Schedule::TodoCategory::NONE.id
        @cur_category = Gws::Schedule::TodoCategory::NONE
      else
        @cur_category = Gws::Schedule::TodoCategory.site(@cur_site).find(params[:category]).root
      end
    end
  end

  def set_search_params
    @s ||= OpenStruct.new(params[:s])
    @s.cur_site ||= @cur_site
    @s.cur_user ||= @cur_user
    @s.todo_state ||= self.class.default_todo_state
    if @cur_category.present?
      @s.category_id ||= @cur_category.id
    end
    @s.grouping ||= self.class.default_groupings
  end

  def pre_params
    super.keep_if { |key| %i[facility_ids].exclude?(key) }.merge(
      start_at: params[:start] || Time.zone.now.strftime('%Y/%m/%d %H:00'),
      end_at: params[:start] || Time.zone.now.strftime('%Y/%m/%d %H:00'),
      member_ids: [@cur_user.id]
    )
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def crud_redirect_url
    path = params.dig(:calendar, :path)
    if path.present? && trusted_url?(path)
      uri = ::Addressable::URI.parse(path)
      uri.query = redirection_calendar_params.to_param
      uri.request_uri
    else
      nil
    end
  end

  def set_skip_default_group
    @skip_default_group = true
  end

  def render_finish_all(result, opts = {})
    location = crud_redirect_url || { action: :index }
    notice = opts[:notice].presence || t("ss.notice.saved")
    errors = @items.map { |item| [item.id, item.errors.full_messages] }

    if result
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to location, notice: notice }
        format.json { head json: errors }
      end
    end
  end

  def item_readable?
    @item.member?(@cur_user) || @item.readable?(@cur_user, site: @cur_site) || @item.allowed?(:read, @cur_user, site: @cur_site)
  end

  public

  def index
    set_items
    @items.page(params[:page]).per(50)
  end

  def show
    raise '403' if !item_readable?
    render
  end

  def popup
    if item_readable?
      render template: 'popup', layout: false
    else
      render template: 'gws/schedule/plans/popup_hidden', layout: false
    end
  end

  # 論理削除
  def soft_delete
    set_item unless @item
    raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    @item.edit_range = params.dig(:item, :edit_range)
    @item.todo_action = params[:action]
    @item.deleted = Time.zone.now
    render_destroy @item.save
  end

  # 完了にする
  def finish
    @item.attributes = fix_params
    raise '403' if !@item.allowed?(:edit, @cur_user, site: @cur_site) && !@item.member?(@cur_user)
    @item.errors.clear
    return if request.get? || request.head?

    comment = Gws::Schedule::TodoComment.new(cur_site: @cur_site, cur_user: @cur_user, cur_todo: @item)
    comment.achievement_rate = 100
    result = comment.save

    result = @item.update(achievement_rate: 100) if result

    render_update result
  end

  # 未完了にする
  def revert
    @item.attributes = fix_params
    raise '403' if !@item.allowed?(:edit, @cur_user, site: @cur_site) && !@item.member?(@cur_user)
    @item.errors.clear
    return if request.get? || request.head?

    comment = Gws::Schedule::TodoComment.new(cur_site: @cur_site, cur_user: @cur_user, cur_todo: @item)
    comment.achievement_rate = 0
    result = comment.save

    result = @item.update(achievement_rate: 0) if result

    render_update result
  end

  # # 削除を取り消す
  # def active
  #   @item.attributes = fix_params
  #   raise '403' unless @item.allowed?(:delete, @cur_user, site: @cur_site)
  #   return if request.get? || request.head?
  #   render_destroy @item.active, {notice: t('gws/schedule/todo.notice.active')}
  # end

  # すべて完了にする
  def finish_all
    @processed_items = []
    error_items = []
    @items.each do |item|
      item.attributes = fix_params
      if item.allowed?(:edit, @cur_user, site: @cur_site) || item.member?(@cur_user)
        comment = Gws::Schedule::TodoComment.new(cur_site: @cur_site, cur_user: @cur_user, cur_todo: item)
        comment.achievement_rate = 100
        result = comment.save

        result = item.update(achievement_rate: 100) if result

        if result
          @processed_items << item
          next
        end
      else
        item.errors.add :base, :auth_error
      end

      error_items << item
    end
    @items = error_items
    render_finish_all(@items.count == 0)
  end

  # すべて未完了にする
  def revert_all
    @processed_items = []
    error_items = []
    @items.each do |item|
      item.attributes = fix_params
      if item.allowed?(:edit, @cur_user, site: @cur_site) || item.member?(@cur_user)
        comment = Gws::Schedule::TodoComment.new(cur_site: @cur_site, cur_user: @cur_user, cur_todo: item)
        comment.achievement_rate = 0
        result = comment.save

        result = item.update(achievement_rate: 0) if result

        if result
          @processed_items << item
          next
        end
      else
        item.errors.add :base, :auth_error
      end

      error_items << item
    end
    @items = error_items
    render_finish_all(@items.count == 0)
  end

  # # すべての削除を取り消す
  # def active_all
  #   entries = @items.entries
  #   @items = []
  #
  #   entries.each do |item|
  #     if item.allowed?(:delete, @cur_user, site: @cur_site)
  #       item.attributes = fix_params
  #       next if item.active
  #     else
  #       item.errors.add :base, :auth_error
  #     end
  #     @items << item
  #   end
  #
  #   location = crud_redirect_url || { action: :index }
  #   notice = { notice: t('gws/schedule/todo.notice.active') }
  #   errors = @items.map { |item| [item.id, item.errors.full_messages] }
  #
  #   respond_to do |format|
  #     format.html { redirect_to location, notice }
  #     format.json { head json: errors }
  #   end
  # end

  def copy
    set_item
    @item = @item.new_clone
    render template: "new"
  end
end
