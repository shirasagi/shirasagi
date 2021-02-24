module Inquiry::AnswersFilter
  extend ActiveSupport::Concern

  included do
    model Inquiry::Answer

    append_view_path "app/views/inquiry/answers"
    append_view_path "app/views/cms/pages"

    before_action :set_items, only: %i[index download]
  end

  private

  def set_items
  end

  def send_afile(file)
    filedata = []
    filepath = file.path
    File.open(filepath, 'rb') do |of|
      filedata = of.read
    end
    if filedata.present? || !filedata.nil?
      send_data(filedata, :filename => file.name)
    end
  end

  public

  def index
    if params[:s].present? && params[:s][:group].present?
      @group = Cms::Group.site(@cur_site).active.find(params[:s][:group])
    end
    @groups = Cms::Group.site(@cur_site).active.tree_sort

    @items = @items.order_by(updated: -1).page(params[:page]).per(50)
  end

  def show
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def edit
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)
  end

  def delete
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render
  end

  def destroy
    raise "403" unless @item.allowed?(:delete, @cur_user, site: @cur_site)
    render_destroy @item.destroy
  end

  def destroy_all
    raise "400" if @selected_items.blank?

    entries = @selected_items
    @items = []

    entries.each do |item|
      item = item.becomes_with_route rescue item
      if item.allowed?(:delete, @cur_user, site: @cur_site, node: @cur_node)
        next if item.destroy
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_destroy_all(entries.size != @items.size)
  end

  def download_afile
    raise "404" if params[:id].blank?

    client_name = Inquiry::Answer.persistence_context.send(:client_name)
    file = SS::File.with(client: client_name) do |model|
      model.where(id: params[:fid].to_i).first
    end
    unless file.blank?
      send_afile file
    end
  end
end
