class Voice::VoiceFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Voice::VoiceFilesFilter

  private
    def set_crumbs
      @crumbs << [:"voice.voice_file", action: :index]
    end

  public
    def index
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        search(@s).
        order_by(updated: -1).
        page(params[:page]).per(50)
      @message = t("views.voice/voice_files.not_exists") if @items.blank?
    end
end
