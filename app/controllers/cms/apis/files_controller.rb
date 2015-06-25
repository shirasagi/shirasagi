class Cms::Apis::FilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include SS::FileFilter
  include SS::AjaxFileFilter

  model Cms::File

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

  public
    def index
      @items = @model.site(@cur_site).
        allow(:read, @cur_user).
        order_by(filename: 1).
        page(params[:page]).per(20)
    end

    def select
      set_item

      item = SS::TempFile.new

      @item.attributes.each do |key, val|
        next if key =~ /^(id|file_id)$/
        next if key =~ /^(group_ids|permission_level)$/
        item.send("#{key}=", val) unless item.send(key)
      end

      #item.state   = "public"
      item.in_file = @item.uploaded_file
      item.save
      item.in_file.delete
      @item = item

      render file: :select, layout: !request.xhr?
    end
end
