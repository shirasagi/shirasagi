class Cms::EditorTemplatesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SearchableCrudFilter
  helper EditorHelper

  model Cms::EditorTemplate
  navi_view "cms/main/navi"

  private
    def set_crumbs
      @crumbs << [:"cms.editor_template", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

  public
    def template
      raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

      @items = @model.site(@cur_site).
        allow(:read, @cur_user, site: @cur_site).
        search(params[:s]).
        page(params[:page]).per(50)

      respond_to do |format|
        format.js { render layout: false, content_type: "application/javascript" }
        format.json { render layout: false, content_type: "application/json" }
      end
    end
end
