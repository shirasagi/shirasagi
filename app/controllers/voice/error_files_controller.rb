class Voice::ErrorFilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Voice::VoiceFilesFilter

  private
    def set_crumbs
      @crumbs << [:"voice.error_file", action: :index]
    end

    def set_search
      s = params[:s]
      if s.present?
        @s = s
        if s[:keyword].present?
          @keyword = s[:keyword]
        end
      end

      @s = {} if @s.nil?
      @s[:has_error] = 1
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
