class Chorg::RevisionsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chorg::Revision

  navi_view "cms/main/conf_navi"

  def download
    set_item
    csv = @item.changesets_to_csv
    filename = "revision_#{@item.name}_#{Time.zone.now.to_i}.csv"
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: filename
  end

  def download_template
    csv = @model.new.changesets_to_csv
    filename = "revision_template.csv"
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: filename
  end

  private

  def set_crumbs
    @crumbs << [t("chorg.revision"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
