class History::Cms::BackupsController < ApplicationController
  include Cms::BaseFilter
  include History::BackupFilter

  model History::Backup

  navi_view "cms/main/navi"

  before_action :set_item

  private
    def set_crumbs
      @crumbs << [:"history.backup", action: :show]
    end

    def set_item
      @item = @model.where("data.site_id" => @cur_site.id).find(params[:id])
      raise "404" unless @data = @item.get
    end
end
