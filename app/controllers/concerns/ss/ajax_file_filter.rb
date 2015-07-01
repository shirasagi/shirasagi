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

      item = SS::TempFile.new

      @item.attributes.each do |key, val|
        next if key =~ /^(id|file_id)$/
        next if key =~ /^(group_ids|permission_level)$/
        item.send("#{key}=", val) unless item.send(key)
      end

      item.in_file = @item.uploaded_file
      item.state   = "public"
      item.name    = @item.name
      item.save
      item.in_file.delete
      @item = item

      render file: :select, layout: !request.xhr?
    end

  public
    def index
      @items = @model
      @items = @items.site(@cur_site) if @cur_site
      @items = @items.allow(:read, @cur_user).
        order_by(filename: 1).
        page(params[:page]).per(20)
    end

    def select
      set_item
      render file: :select, layout: !request.xhr?
    end
end
