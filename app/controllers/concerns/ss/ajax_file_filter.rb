module SS::AjaxFileFilter
  extend ActiveSupport::Concern

  included do
    layout "ss/ajax"
  end

  private

  def append_view_paths
    append_view_path "app/views/ss/crud/ajax_files"
    super
  end

  def select_with_clone
    set_item

    @item = @item.copy(
      cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node
    )
    @page = Cms::Page.find_or_initialize_by(id: params[:owner_item_id])
    @page = @page.becomes_with_route(params[:owner_item_type].underscore) if params[:owner_item_type].present?

    render template: "select", layout: !request.xhr?
  end

  public

  def index
    @items = @model
    @items = @items.site(@cur_site) if @cur_site
    @items = @items.where(content_type: /^image\//) if self.class.only_image
    @items = @items.allow(:read, @cur_user).
      order_by(filename: 1).
      page(params[:page]).per(20)
  end

  def select
    set_item
    @page = Cms::Page.find_or_initialize_by(id: params[:owner_item_id])
    @page = @page.becomes_with_route(params[:owner_item_type].underscore) if params[:owner_item_type].present?
    render template: "select", layout: !request.xhr? && SS.file_upload_dialog == :v1
  end

  def selected_files
    @select_ids = params[:select_ids].to_a
    @items = @model
    @items = @items.site(@cur_site) if @cur_site
    @items = @items.allow(:read, @cur_user).
      in(id: @select_ids).
      order_by(filename: 1)
    render template: "index"
  end
end
