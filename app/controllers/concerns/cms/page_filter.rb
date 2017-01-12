module Cms::PageFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  included do
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :lock, :unlock, :move, :copy, :contain_links]
    before_action :set_contain_link_items, only: [:contain_links, :edit, :delete]
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

    def set_items
      @items = @model.site(@cur_site).node(@cur_node)
        .allow(:read, @cur_user)
        .order_by(updated: -1)
    end

    def set_contain_link_items
      @contain_link_items = []
      return unless @item.class.include?(Cms::Model::Page)

      cond = []
      if @item.respond_to?(:url) && @item.respond_to?(:full_url)
        urls = [@item.url, @item.full_url]
        urls.each do |url|
          cond << { html: /href="#{Regexp.escape(url)}/ }
        end
      end

      if @item.respond_to?(:files)
        @item.files.each do |file|
          cond << { html: /(href|src)="#{Regexp.escape(file.url)}/ }
        end
      end

      if @item.respond_to?(:related_page_ids)
        cond << { related_page_ids: { '$in' => [ @item.id ] } }
      end

      if cond.present?
        @contain_link_items = Cms::Page.site(@cur_site).where(:id.ne => @item.id).or(cond).
          page(params[:page]).per(50)
      end
    end

  public
    def index
      if @cur_node
        raise "403" unless @cur_node.allowed?(:read, @cur_user, site: @cur_site)

        set_items
        @items = @items.search(params[:s]).
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
        master = @item.master
        @item.delete
        master.generate_file
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

    def contain_links
      raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
      render
    end

    def set_tag_all
      if @cur_node
        safe_params = params.permit(:tag, ids: [])
        ids = safe_params[:ids].presence || []
        tag = safe_params[:tag].presence
        if tag
          @model.site(@cur_site).node(@cur_node).in(_id: ids).allow(:edit, @cur_user).each do |item|
            item.add_to_set(tags: [ tag ])
          end
        end
      end

      render_update true, location: { action: :index }, render: { file: :index }
    end

    def reset_tag_all
      if @cur_node
        safe_params = params.permit(:tag, ids: [])
        ids = safe_params[:ids].presence || []
        tag = safe_params[:tag].presence
        if tag
          @model.site(@cur_site).node(@cur_node).in(_id: ids).allow(:edit, @cur_user).each do |item|
            item.pull(tags: tag)
          end
        end
      end

      render_update true, location: { action: :index }, render: { file: :index }
    end
end
