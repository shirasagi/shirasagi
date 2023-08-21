module Member::AjaxFileFilter
  extend ActiveSupport::Concern
  include Member::AuthFilter

  included do
    layout "member/ajax"
    before_action :set_items
  end

  private

  def logged_in?
    set_member

    ## required self
    member = get_member_by_session
    raise "404" unless member
    raise "404" if @cur_member.id != member.id
  end

  def set_member
    @cur_member = Cms::Member.find params[:member]
    @cur_site = SS.current_site = @cur_member.site
  end

  def set_last_modified
    response.headers["Last-Modified"] = CGI::rfc1123_date(@item.updated.in_time_zone)
  end

  def append_view_paths
    append_view_path "app/views/member/crud/ajax_files"
    super
  end

  def fix_params
    { cur_member: @cur_member }
  end

  def set_items
    @items = @model.allow(:read, @cur_member)
  end

  def set_item
    set_items

    @item ||= begin
      item = @items.find(params[:id])
      item.attributes = fix_params
      item
    end
  rescue Mongoid::Errors::DocumentNotFound => e
    return render_destroy(true) if params[:action] == 'destroy'
    raise e
  end

  public

  def index
    @items = @items.
      order_by(filename: 1).
      page(params[:page]).per(20)
  end

  def select
    set_item
    render template: "select", layout: !request.xhr?
  end

  def selected_files
    @select_ids = params[:select_ids].to_a
    @items = @items.
      in(id: @select_ids).
      order_by(filename: 1)
    render template: "index"
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
    raise "404" unless Fs.file?(@item.path)

    set_last_modified
    ss_send_file @item, type: @item.content_type, filename: @item.filename, disposition: :inline
  end

  def thumb
    set_item
    raise "404" unless Fs.file?(@item.path)

    set_last_modified

    if (thumb = @item.try(:thumb)) && Fs.file?(thumb.path)
      ss_send_file thumb, type: thumb.content_type, filename: thumb.filename, disposition: :inline
      return
    end

    converter = SS::ImageConverter.open(@item.path)
    converter.resize_to_fit!

    send_enum converter.to_enum, type: @item.content_type, filename: @item.filename, disposition: :inline
    converter = nil
  rescue
    raise "500"
  ensure
    if converter
      converter.close rescue nil
    end
  end

  def download
    set_item
    raise "404" unless Fs.file?(@item.path)

    set_last_modified
    ss_send_file @item, type: @item.content_type, filename: @item.filename, disposition: :attachment
  end

  module ClassMethods
    private

    def model(cls)
      self.model_class = cls if cls
    end
  end
end
