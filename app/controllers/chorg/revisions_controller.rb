class Chorg::RevisionsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chorg::Revision

  navi_view "cms/main/conf_navi"

  def download
    set_item
    exporter = Chorg::ChangesetExporter.new(cur_site: @cur_site, cur_user: @cur_user, revision: @item)
    enumerable = exporter.enum_csv(encoding: "UTF-8")
    filename = "revision_#{@item.name}_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  def download_sample_csv
    exporter = Chorg::ChangesetExporter.new(cur_site: @cur_site, cur_user: @cur_user)
    enumerable = exporter.enum_sample_csv(encoding: "UTF-8")
    filename = "revision_sample.csv"
    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  private

  def set_crumbs
    @crumbs << [t("chorg.revision"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
