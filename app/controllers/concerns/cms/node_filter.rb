module Cms::NodeFilter
  extend ActiveSupport::Concern
  include Cms::CrudFilter

  included do
    before_action :set_item, only: [:show, :edit, :update, :delete, :destroy, :move]
    before_action :change_item_class, if: -> { @item.present? }
  end

  private
    def append_view_paths
      append_view_path ["app/views/cms/nodes", "app/views/ss/crud"]
    end

    def set_item
      super
      raise "404" if @cur_node && @item.id == @cur_node.id
    end

    def change_item_class
      @item.route = params[:route] if params[:route]
      @item  = @item.becomes_with_route rescue @item
      @model = @item.class
    end

    def redirect_url
      diff = @item.route.pluralize != params[:controller]
      diff ? node_node_path(cid: @cur_node, id: @item.id) : { action: :show, id: @item.id }
    end

  public
    def index
      @items = @model.site(@cur_site).node(@cur_node).
        allow(:read, @cur_user).
        search(params[:s]).
        order_by(filename: 1).
        page(params[:page]).per(50)
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      change_item_class

      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    end

    def create
      @item = @model.new get_params
      change_item_class
      @item.attributes = get_params

      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      render_create @item.save, location: redirect_url
    end

    def update
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
      render_update @item.update, location: redirect_url
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
        render_update @item.move(destination), location: { action: :move, source: @source }, render: { file: :move }
      end
    end
end
