module Sns::CrudFilter
  extend ActiveSupport::Concern
  include SS::CrudFilter

  included do
    menu_view "ss/crud/menu"
  end

  private
    def append_view_paths
      append_view_path "app/views/sns/crud"
      append_view_path "app/views/ss/crud"
    end

  public
    def index
      #raise "403" unless @model.allowed?(:read, @cur_user)

      @items = @model.site(@cur_site).
        allow(:read, @cur_user).
        search(params[:s]).
        page(params[:page]).per(50)
    end

    def show
      raise "403" unless @item.allowed?(:read, @cur_user)
      render
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      raise "403" unless @item.allowed?(:edit, @cur_user)
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      render_create @item.save
    end

    def edit
      raise "403" unless @item.allowed?(:edit, @cur_user)
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
      raise "403" unless @item.allowed?(:edit, @cur_user)
      render_update @item.update
    end

    def delete
      raise "403" unless @item.allowed?(:delete, @cur_user)
      render
    end

    def destroy
      raise "403" unless @item.allowed?(:delete, @cur_user)
      render_destroy @item.destroy
    end

    def destroy_all
      entries = @items.entries
      @items = []

      entries.each do |item|
        if item.allowed?(:delete, @cur_user)
          next if item.destroy
        else
          item.errors.add :base, :auth_error
        end
        @items << item
      end
      render_destroy_all(entries.size != @items.size)
    end
end
