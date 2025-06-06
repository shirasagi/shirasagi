class Gws::Tabular::File::CsvImportJob < Gws::ApplicationJob
  include Job::Gws::Binding::Group # 兼務対応
  include Cms::CsvImportBase
  include SS::ZipFileImport
  include Gws::Tabular::File::ImportNotification

  self.required_headers = ->{ [ I18n.t("mongoid.attributes.gws/tabular/file.id") ] }

  class << self
    alias valid_file? valid_csv?
  end

  def perform(space_id, _form_id, release_id, temp_file_id)
    @cur_space = Gws::Tabular::Space.site(site).find(space_id)
    @cur_release = Gws::Tabular::FormRelease.find(release_id)

    @cur_file = SS::File.find(temp_file_id)
    Rails.logger.tagged(@cur_file.filename) do
      import_file
    end

    send_notification(:success)
  rescue
    send_notification(:failure)
    raise
  ensure
    if @cur_file && @cur_file.model == 'ss/temp_file'
      @cur_file.destroy
    end
  end

  private

  def import_file
    importer = Gws::Tabular::File::CsvImporter.new(
      site: site, user: user, user_group: group, space: @cur_space, release: @cur_release, path_or_io: @cur_file.path)
    importer.call
  end
end
