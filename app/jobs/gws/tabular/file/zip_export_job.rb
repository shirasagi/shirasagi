class Gws::Tabular::File::ZipExportJob < Gws::ApplicationJob
  def perform(space_id, form_id, release_id, encoding, *ids)
    @cur_space = Gws::Tabular::Space.site(site).find(space_id)
    @cur_release = Gws::Tabular::FormRelease.find(release_id)
    @cur_form = Gws::Tabular.released_form(@cur_release, site: site)
    @cur_form ||= Gws::Tabular::Form.find(form_id)
    @cur_columns = Gws::Tabular.released_columns(@cur_release, site: site)
    @cur_columns ||= @cur_form.columns.reorder(order: 1, id: 1).to_a
    @model = Gws::Tabular::File[@cur_release]

    ids = Array(ids)
    ids.flatten!
    @ids = ids

    filename = "gws_tabular_files.zip"
    @zip = Gws::Compressor.new(
      user, {
        model: @model, items: @model.none, filename: filename,
        name: "#{@cur_form.i18n_name}_#{Time.zone.now.to_i}.zip"
      }
    )
    @zip.url = download_file_url(filename)

    @final_path = @zip.path
    @temp_path = "#{::File.dirname(@final_path)}/.#{::File.basename(@final_path)}.$$"
    @url = @zip.url

    ::FileUtils.mkdir_p(::File.dirname(@final_path))
    comment = "shirasagi #{SS.version} gws tabular file data created at #{Time.zone.now.iso8601}"
    SS::Zip::Writer.create(@temp_path, comment: comment) do |zip|
      export_csv_to_zip(zip, encoding)

      each_attachment_file do |item, file|
        next unless ::File.exist?(file.path)

        name = ::Fs.zip_safe_path("#{item.id}/#{file.id}_#{file.filename}")
        zip.add_file(name) do |output|
          ::IO.copy_stream(file.path, output)
        end
      end
    end

    ::FileUtils.rm_f(@final_path) rescue nil
    ::FileUtils.mv(@temp_path, @final_path, force: true) rescue nil
    ::FileUtils.rm_f(@temp_path) rescue nil

    send_notification
  rescue
    ::FileUtils.rm_f(@temp_path) rescue nil
    raise
  end

  private

  def download_file_url(filename)
    scheme = site.canonical_scheme.presence || SS.config.gws.canonical_scheme.presence || "http"
    domain = site.canonical_domain.presence || SS.config.gws.canonical_domain
    Rails.application.routes.url_helpers.sns_download_job_files_url(
      protocol: scheme, host: domain, user: user, filename: filename)
  end

  def export_csv_to_zip(zip, encoding)
    criteria = @model.all.site(site).in(id: @ids)
    exporter = Gws::Tabular::File::CsvExporter.new(
      site: site, user: user, space: @cur_space, form: @cur_form, release: @cur_release, criteria: criteria)

    name = ::Fs.zip_safe_path("files.csv")
    zip.add_file(name) do |output|
      exporter.enum_csv(encoding: encoding).each do |csv_row|
        output.write(csv_row)
      end
    end
  end

  def each_attachment_file
    file_columns = @cur_columns.select { |column| column.is_a?(::Gws::Tabular::Column::FileUploadField) }
    return if file_columns.blank?

    criteria = @model.all.site(site)
    @ids.each_slice(100) do |ids|
      criteria.in(id: ids).to_a.each do |item|
        file_columns.each do |file_column|
          file_value = item.read_tabular_value(file_column)
          next if file_value.blank?
          next unless ::File.exist?(file_value.path)

          yield item, file_value
        end
      end
    end
  end

  def send_notification
    return unless user.use_notice?(Gws::Tabular::File)

    item = Gws::Share::Mailer.compressed_mail(site, user, @zip).message

    subject = item.subject
    subject = NKF.nkf("-w", subject) if subject.match?(/ISO-2022-JP/i)

    message = SS::Notification.new
    message.cur_group = site
    message.cur_user = user
    message.member_ids = [ user.id ]
    message.send_date = Time.zone.now
    message.subject = subject
    message.format = 'text'
    message.text = item.decoded
    message.save!
  end
end
