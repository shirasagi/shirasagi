module Cms::CrudFilter
  extend ActiveSupport::Concern
  include SS::CrudFilter
  include Cms::LockFilter

  included do
    menu_view "cms/crud/menu"
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy]
  end

  private

  def append_view_paths
    append_view_path "app/views/cms/crud"
    append_view_path "app/views/ss/crud"
  end

  def set_item
    @item = @model.site(@cur_site).find(params[:id])
    @item.attributes = fix_params
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  def set_items
    @items = @model.site(@cur_site).
      allow(:read, @cur_user, site: @cur_site)
  end

  def set_selected_items
    ids = params[:ids]
    raise "400" unless ids
    ids = ids.split(",") if ids.is_a?(String)
    @selected_items = @items = @model.in(id: ids).site(@cur_site)
    raise "400" unless @items.present?
  end

  def destroy_items
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        item.cur_user = @cur_user if item.respond_to?(:cur_user)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    entries.size != @items.size
  end

  def change_items_state
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    role_action = :edit
    if @model.include?(Cms::Addon::Release)
      role_action = :release if @change_state == 'public'
      role_action = :close if @change_state == 'closed'
    end

    entries.each do |item|
      if item.allowed?(role_action, @cur_user, site: @cur_site, node: @cur_node)
        item.cur_user = @cur_user if item.respond_to?(:cur_user)
        item.state = @change_state if item.respond_to?(:state)
        next if item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    entries.size != @items.size
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    set_items
    @items = @items.search(params[:s])
      .page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)
    render
  end

  def new
    @item = @model.new pre_params.merge(fix_params)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
  end

  def create
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_create @item.save
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    if @item.is_a?(Cms::Addon::EditLock)
      unless @item.acquire_lock
        redirect_to action: :lock
        return
      end
    end
    render
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    render_update @item.update
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
    render
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
    @item.cur_user = @cur_user if @item.respond_to?(:cur_user)
    render_destroy @item.destroy
  end

  def destroy_all
    raise "400" if @selected_items.blank?

    if params[:destroy_all]
      render_confirmed_all(destroy_items, location: SS.request_path(request))
      return
    end

    respond_to do |format|
      format.html { render "cms/crud/destroy_all" }
      format.json { head json: errors }
    end
  end

  def disable_all
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        if item.deletion_unlocked? && item.disabled?
          item.destroy
          next
        end
        next if item.disable
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_confirmed_all(entries.size != @items.size)
  end

  def change_state_all
    raise "400" if @selected_items.blank?

    @change_state = params[:state]
    if params[:change_state_all]
      render_confirmed_all(change_items_state, location: SS.request_path(request))
      return
    end

    respond_to do |format|
      format.html { render "cms/crud/change_state_all" }
      format.json { head json: errors }
    end
  end

  def publish_all
    raise "400" if @selected_items.blank?

    @change_state = params[:state]

    if params[:change_state_all]
      render_confirmed_all(change_items_state, location: url_for(action: :index), notice: t("ss.notice.published"))
      return
    end

    respond_to do |format|
      format.html { render "cms/pages/publish_all" }
      format.json { head json: errors }
    end
  end

  def close_all
    raise "400" if @selected_items.blank?

    @change_state = params[:state]

    if params[:change_state_all]
      entries = @selected_items.entries
      @items = []

      Rails.logger.info("一括非公開処理開始: #{entries.size}件のページを処理")

      entries.each do |item|
        if item.allowed?(:close, @cur_user, site: @cur_site)
          contains_urls = Cms.contains_urls(item, site: @cur_site)
          if contains_urls.present?
            Rails.logger.info("リンクが含まれているページを検出: #{item.name} (ID: #{item.id})")
            if @cur_user.cms_role_permit_any?(@cur_site, %w(edit_cms_ignore_alert))
              item.state = 'closed'
              if item.save
                Rails.logger.info("ページを非公開に変更: #{item.name} (ID: #{item.id})")
                next
              else
                Rails.logger.error("ページの非公開処理に失敗: #{item.name} (ID: #{item.id}) - #{item.errors.full_messages.join(', ')}")
              end
            else
              Rails.logger.warn("権限不足により非公開処理をスキップ: #{item.name} (ID: #{item.id})")
              item.errors.add :base, t("ss.confirm.not_allowed_to_close")
            end
          else
            item.state = 'closed'
            if item.save
              Rails.logger.info("ページを非公開に変更: #{item.name} (ID: #{item.id})")
              next
            else
              Rails.logger.error("ページの非公開処理に失敗: #{item.name} (ID: #{item.id}) - #{item.errors.full_messages.join(', ')}")
            end
          end
        else
          Rails.logger.warn("権限不足により非公開処理をスキップ: #{item.name} (ID: #{item.id})")
          item.errors.add :base, :auth_error
        end
        @items << item
      end

      Rails.logger.info("一括非公開処理完了: 成功 #{entries.size - @items.size}件, 失敗 #{@items.size}件")
      render_confirmed_all(entries.size != @items.size, location: url_for(action: :index), notice: t("ss.notice.depublished"),
error: t("ss.notice.error"))
      return
    end

    respond_to do |format|
      format.html { render "cms/pages/close_all" }
      format.json { head json: errors }
    end
  end
end
