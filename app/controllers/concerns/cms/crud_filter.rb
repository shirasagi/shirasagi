module Cms::CrudFilter
  extend ActiveSupport::Concern
  include SS::CrudFilter

  included do
    menu_view "cms/crud/menu"
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :lock, :unlock]
  end

  private
    def append_view_paths
      append_view_path "app/views/cms/crud"
      append_view_path "app/views/ss/crud"
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        order_by(_id: -1).
        page(params[:page]).per(50)
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
      render_destroy @item.destroy
    end

    def destroy_all
      entries = @items.entries
      @items = []

      entries.each do |item|
        if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
          next if item.destroy
        else
          item.errors.add :base, :auth_error
        end
        @items << item
      end
      render_destroy_all(entries.size != @items.size)
    end

    def lock
      if @item.acquire_lock(force: params[:force].present?)
        render
      else
        respond_to do |format|
          format.html { render }
          format.json { render json: [ t("views.errors.locked", user: @item.lock_owner.long_name) ], status: :locked }
        end
      end
    end

    def unlock
      unless @item.locked?
        respond_to do |format|
          format.html { redirect_to(action: :edit) }
          format.json { head :no_content }
        end
        return
      end

      raise "403" if !@item.lock_owned? && !@item.allowed?(:unlock, @cur_user, site: @cur_site, node: @cur_node)

      if @item.release_lock(force: params[:force].present?)
        respond_to do |format|
          format.html { redirect_to(action: :edit) }
          format.json { head :no_content }
        end
      else
        respond_to do |format|
          format.html { render file: :show }
          format.json { render json: [ t("views.errors.locked", user: @item.lock_owner.long_name) ], status: :locked }
        end
      end
    end
end
