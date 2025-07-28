class Gws::Tabular::File::ZipImportJob < Gws::ApplicationJob
  include Job::Gws::Binding::Group # 兼務対応
  include Gws::Tabular::File::ImportNotification

  cattr_accessor(:required_headers, instance_accessor: false)
  self.required_headers = -> do
    [ I18n.t("mongoid.attributes.gws/tabular/file.id") ]
  end

  class << self
    def valid_zip?(file, max_read_lines: nil)
      found = false
      valid = false
      Zip::File.open(file) do |zip_archive|
        zip_archive.each do |zip_entry|
          next if zip_entry.directory?

          zip_entry_name = ::SS::Zip.safe_zip_entry_name(zip_entry)
          zip_entry_name = ::File.basename(zip_entry_name)
          zip_entry_name = zip_entry_name.downcase
          next unless zip_entry_name == "files.csv"

          found = true
          Tempfile.create("gws_tabular", "#{Rails.root}/tmp") do |tempfile|
            zip_entry.get_input_stream { |f| ::IO.copy_stream(f, tempfile) }
            tempfile.flush
            tempfile.pos = 0

            valid = valid_csv?(tempfile, max_read_lines: max_read_lines)
          end
          break
        end
      end

      found && valid
    rescue => e
      logger.info { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
      false
    end
    alias valid_file? valid_zip?

    private

    def valid_csv?(io, max_read_lines: nil)
      I18n.with_locale(I18n.default_locale) do
        if required_headers.respond_to?(:call)
          headers = class_exec(&required_headers)
        else
          headers = required_headers
        end

        SS::Csv.valid_csv?(io, headers: true, required_headers: headers, max_rows: max_read_lines)
      end
    end

    # def each_csv(io, &block)
    #   I18n.with_locale(I18n.default_locale) do
    #     SS::Csv.foreach_row(io, headers: true, &block)
    #   end
    # end
  end

  def perform(space_id, form_id, release_id, temp_file_id)
    @cur_space = Gws::Tabular::Space.site(site).find(space_id)
    @cur_release = Gws::Tabular::FormRelease.find(release_id)

    @cur_file = SS::File.find(temp_file_id)
    Rails.logger.tagged(@cur_file.name) do
      import_zip_file
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

  def import_zip_file
    ::Zip::File.open(@cur_file.path) do |zip_archive|
      import_zip_archive(zip_archive)
    end
  end

  def import_zip_archive(zip_archive)
    csv_entry = find_csv_file(zip_archive)
    unless csv_entry
      Rails.logger.info { "'files.csv' is not found in the zip" }
      return
    end

    csv_entry_name = ::SS::Zip.safe_zip_entry_name(csv_entry)
    Rails.logger.tagged(csv_entry_name) do
      basedir = ::File.dirname(csv_entry_name)
      basedir = nil if basedir == "."

      ::Tempfile.create("gws_tabular", "#{Rails.root}/tmp") do |f|
        csv_entry.get_input_stream { |io| ::IO.copy_stream(io, f) }
        f.flush

        import_csv_file(zip_archive, basedir, f.path)
      end
    end
  end

  def find_csv_file(zip_archive)
    csv_entry = zip_archive.find_entry("files.csv")
    return csv_entry if csv_entry

    zip_archive.each do |zip_entry|
      next if zip_entry.directory?

      zip_entry_name = ::SS::Zip.safe_zip_entry_name(zip_entry)
      zip_entry_name = ::File.basename(zip_entry_name)
      zip_entry_name = zip_entry_name.downcase
      if zip_entry_name == "files.csv"
        csv_entry = zip_entry
        break
      end
    end

    csv_entry
  end

  def import_csv_file(zip_archive, basedir, csv_path)
    importer = Gws::Tabular::File::CsvImporter.new(
      site: site, user: user, user_group: group, space: @cur_space, release: @cur_release, path_or_io: csv_path)

    importer.zip_archive = zip_archive
    importer.zip_basedir = basedir
    importer.call
  end
end
