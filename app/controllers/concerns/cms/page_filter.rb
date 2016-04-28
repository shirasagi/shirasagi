module Cms::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  included do
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :lock, :unlock, :move, :copy]
    before_action :set_selected_items, only: [:destroy_all, :download]
  end

  private
    def set_item
      super
      return unless @cur_node
      return if (@item.filename =~ /^#{@cur_node.filename}\//) && (@item.depth == @cur_node.depth + 1)
      raise "404"
    end

    def pre_params
      if @cur_node
        layout_id = @cur_node.page_layout_id || @cur_node.layout_id
        { layout_id: layout_id }
      else
        {}
      end
    end

  public
    def index
      if @cur_node
        raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

        @items = @model.site(@cur_site).node(@cur_node).
          allow(:read, @cur_user).
          search(params[:s]).
          order_by(updated: -1).
          page(params[:page]).per(50)
      end
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_user)
      if @item.state == "public"
        raise "403" unless @item.allowed?(:release, @cur_user)
        @item.state = "ready" if @item.try(:release_date).present?
      end
      render_create @item.save
    end

    def update
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      raise "403" unless @item.allowed?(:edit, @cur_user)
      if @item.state == "public"
        raise "403" unless @item.allowed?(:release, @cur_user)
        @item.state = "ready" if @item.try(:release_date).present?
      end

      result = @item.update
      location = nil
      if result && @item.try(:branch?) && @item.state == "public"
        location = { action: :index }
        @item.delete
      end
      render_update result, location: location
    end

    def move
      @filename   = params[:filename]
      @source     = params[:source]
      @link_check = params[:link_check]
      destination = params[:destination]
      confirm     = params[:confirm]

      if request.get?
        @filename = @item.filename
      elsif confirm
        @source = "/#{@item.filename}"
        @item.validate_destination_filename(destination)
        @item.filename = destination
        @link_check = @item.errors.empty?
      else
        @source = "/#{@item.filename}"
        raise "403" unless @item.allowed?(:move, @cur_user, site: @cur_site, node: @cur_node)

        node = Cms::Node.site(@cur_site).filename(::File.dirname(destination)).first

        if node.blank?
          location = move_cms_page_path id: @item.id, source: @source, link_check: true
        elsif @item.route == "cms/page"
          location = move_node_page_path cid: node.id, id: @item.id, source: @source, link_check: true
        else
          location = { cid: node.id, action: :move, source: @source, link_check: true }
        end

        render_update @item.move(destination), location: location, render: { file: :move }
      end
    end

    def copy
      if request.get?
        prefix = I18n.t("workflow.cloned_name_prefix")
        @item.name = "[#{prefix}] #{@item.name}" unless @item.cloned_name?
        return
      end

      @item.attributes = get_params
      @copy = @item.new_clone
      render_update @copy.save, location: { action: :index }, render: { file: :copy }
    end
end
