module Member::AjaxFileFilter
  extend ActiveSupport::Concern
  include Member::AuthFilter

  included do
    before_action :set_member
    before_action :logged_in?
    layout "member/ajax"
  end

  private
    def set_member
      @cur_member = Cms::Member.find params[:member]
      @cur_site = @cur_member.site
    end

    def logged_in?
      member = get_member_by_session(@cur_site)

      ## required self
      raise "403" unless member
      raise "403" if @cur_member.id != member.id
    end

    def set_last_modified
      response.headers["Last-Modified"] = CGI::rfc1123_date(@item.updated.in_time_zone)
    end

    def append_view_paths
      append_view_path "app/views/member/crud/ajax_files"
      super
    end

  public
    def index
      @items = @model
      #@items = @items.site(@cur_site) if @cur_site
      @items = @items.allow(:read, @cur_member).
        order_by(filename: 1).
        page(params[:page]).per(20)
    end

    def select
      set_item
      render file: :select, layout: !request.xhr?
    end

    def show
      render
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
    end

    def create
      @item = @model.new get_params
      raise "403" unless @item.allowed?(:edit, @cur_member, site: @cur_site)

      if @item.in_files
        render_create @item.save_files, location: { action: :index }
      else
        render_create @item.save
      end
    end

    def edit
      render
    end

    def update
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      render_update @item.update
    end

    def destroy
      render_destroy @item.destroy
    end

    def view
      set_item
      set_last_modified

      if Fs.mode == :file && Fs.file?(@item.path)
        send_file @item.path, type: @item.content_type, filename: @item.filename,
          disposition: :inline, x_sendfile: true
      else
        send_data @item.read, type: @item.content_type, filename: @item.filename,
          disposition: :inline
      end
    end

    def thumb
      set_item
      set_last_modified

      if @item.try(:thumb)
        return send_file @item.thumb.path, type: @item.content_type, filename: @item.filename, disposition: :inline
      end

      require 'rmagick'
      image = Magick::Image.from_blob(@item.read).shift
      image = image.resize_to_fit 120, 90 if image.columns > 120 || image.rows > 90

      send_data image.to_blob, type: @item.content_type, filename: @item.filename, disposition: :inline
    rescue
      raise "500"
    end

    def download
      set_item
      set_last_modified

      if Fs.mode == :file && Fs.file?(@item.path)
        send_file @item.path, type: @item.content_type, filename: @item.filename,
          disposition: :attachment, x_sendfile: true
      else
        send_data @item.read, type: @item.content_type, filename: @item.filename,
          disposition: :attachment
      end
    end

    module ClassMethods
      private
        def model(cls)
          self.model_class = cls if cls
        end
    end
end
