class Chorg::RevisionsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Chorg::Revision

  navi_view "cms/main/conf_navi"

  def download_changesets
    set_item
    raise "403" unless @item.allowed?(:read, @cur_user, site: @cur_site)

    exporter = Chorg::ChangesetExporter.new(cur_site: @cur_site, cur_user: @cur_user, revision: @item)
    enumerable = exporter.enum_csv(encoding: "UTF-8")
    filename = "revision_#{@item.name}_#{Time.zone.now.to_i}.csv"
    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  def download_sample_csv
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site)

    exporter = Chorg::ChangesetExporter.new(cur_site: @cur_site, cur_user: @cur_user)
    enumerable = exporter.enum_sample_csv(encoding: "UTF-8")
    filename = "revision_sample.csv"
    response.status = 200
    send_enum enumerable, type: enumerable.content_type, filename: filename
  end

  def import_changesets
    set_item
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site)

    if request.get? || request.head?
      render
      return
    end

    file = params[:item].try(:[], :in_file)
    if file.nil? || ::File.extname(file.original_filename) != ".csv"
      @item.errors.add :base, I18n.t("errors.messages.invalid_csv")
      render
      return
    end
    if !Chorg::ChangesetImportJob.valid_csv?(file)
      @item.errors.add :base, I18n.t("errors.messages.malformed_csv")
      render
      return
    end

    temp_file = SS::TempFile.create_empty!(model: 'ss/temp_file', filename: file.original_filename) do |new_file|
      IO.copy_stream(file, new_file.path)
    end

    Chorg::ChangesetImportJob.bind(site_id: @cur_site, user_id: @cur_user).perform_now(@item.id, temp_file.id)
    render_update true, notice: I18n.t("ss.notice.imported")
  end

  private

  def set_crumbs
    @crumbs << [t("chorg.revision"), action: :index]
  end

  def fix_params
    { cur_site: @cur_site }
  end

  def crud_redirect_url
    return if params[:action] != "create" || !params.key?(:save_and_import_changesets) || !@item.persisted?
    url_for(action: :import_changesets, id: @item)
  end
end
