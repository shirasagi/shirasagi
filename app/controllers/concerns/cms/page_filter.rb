module Cms::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  included do
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :move, :copy]
  end

  private
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
        @item.state = "ready" if @item.release_date
      end
      render_create @item.save
    end

    def update
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      raise "403" unless @item.allowed?(:edit, @cur_user)
      if @item.state == "public"
        raise "403" unless @item.allowed?(:release, @cur_user)
        @item.state = "ready" if @item.release_date
      end

      result = @item.update
      location = nil
      if result && @item.try(:branch?) && @item.state != "closed"
        location = { action: :index }
        @item.delete
      end
      render_update result, location: location
    end

    def move
      @filename = params[:filename]
      @source = params[:source]
      destination = params[:destination]
      confirm = params[:confirm]

      if request.get? || confirm
        if confirm
          @item.validate_destination_filename(destination)
          @item.filename = destination
        end

        if @item.errors.empty? && @source.present?
          path = ("=\"/#{@source}" =~ /\.html$/) ? "=\"/#{@source}" : "=\"/#{@source}/"
          words = [ path ]
          words << "=\"/#{@source.sub(/index.html$/, "")}" if @source =~ /\/index.html$/
          words = words.join(" ")

          cond = Cms::Page.keyword_in(words, :html, :question).selector
          cond["$or"] = cond["$and"]
          cond.delete("$and")

          @pages = Cms::Page.site(@cur_site).where(cond).limit(500)
          @parts = Cms::Part.site(@cur_site).where(cond).limit(500)
          @layouts = Cms::Layout.site(@cur_site).where(cond).limit(500)
        end

        @source ||= @item.filename
        @filename ||= @item.filename
      else
        raise "403" unless @item.allowed?(:move, @cur_user, site: @cur_site, node: @cur_node)

        result = @item.move(destination)
        cid = @item.parent.try(:id)
        location = { action: :move, cid: cid, source: @source }
        if @item.route == "cms/page"
          if cid
            location = move_node_page_path(id: @item.id, cid: cid, source: @source)
          else
            location = move_cms_page_path(id: @item.id, source: @source)
          end
        end

        render_update result, location: location, render: { file: :move }
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
