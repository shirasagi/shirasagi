class Cms::AllContentsController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/main/navi"

  private

  def set_crumbs
    @crumbs << [t("cms.all_contents"), cms_all_contents_path]
    case params[:action]
    when 'download_all'
      @crumbs << [t("cms.all_content.download_tab"), cms_all_contents_download_path]
    when 'import'
      @crumbs << [t("cms.all_content.import_tab"), cms_all_contents_import_path]
    end
  end

  public

  def download_all
    respond_to do |format|
      format.html
      format.csv do
        response.status = 200
        send_enum Cms::AllContent.enum_csv(@cur_site),
                  type: 'text/csv; charset=Shift_JIS',
                  filename: "all_contents_#{Time.zone.now.to_i}.csv"
      end
    end
  end

  def import
    if request.get?
      render
      return
    end

    raise NotImplementedError
  end
end
