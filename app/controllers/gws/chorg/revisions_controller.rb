class Gws::Chorg::RevisionsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view 'gws/main/conf_navi'
  model Gws::Chorg::Revision
  append_view_path 'app/views/chorg/revisions'

  def download_changesets
    set_item
    raise "404" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    csv = @item.changesets_to_csv
    filename = "revision_#{@item.name}_#{Time.zone.now.to_i}.csv"
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: filename
  end

  def download_sample_csv
    csv = @model.new.changesets_sample_csv
    filename = "revision_sample.csv"
    send_data csv.encode("SJIS", invalid: :replace, undef: :replace), filename: filename
  end

  private

  def set_crumbs
    @crumbs << [t('modules.gws/chorg'), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end
end
