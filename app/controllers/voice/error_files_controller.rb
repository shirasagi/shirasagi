class Voice::ErrorFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Voice::FilesFilter

  private

  def set_crumbs
    @crumbs << [t("voice.error_file"), action: :index]
  end

  def set_search
    @s ||= begin
      s = OpenStruct.new(params[:s])
      @keyword = s.keyword
      s[:has_error] = 1
      s
    end
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @items = @model.site(@cur_site).
        search(@s).
        order_by(updated: -1).
        page(params[:page]).per(50)

    @message = t("views.voice/error_files.not_exists") if @items.blank?
  end
end
