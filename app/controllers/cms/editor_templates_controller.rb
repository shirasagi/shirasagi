class Cms::EditorTemplatesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  helper SS::EditorHelper

  model Cms::EditorTemplate
  navi_view "cms/main/conf_navi"

  private
    def set_crumbs
      @crumbs << [:"cms.editor_template", action: :index]
    end

    def fix_params
      { cur_site: @cur_site }
    end

  public
    def template
      @items = @model.site(@cur_site).search(params[:s])

      respond_to do |format|
        format.js { render layout: false, content_type: "application/javascript" }
        format.json { render layout: false, content_type: "application/json" }
      end
    end
end
