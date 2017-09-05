module Sys::SiteCopy::SsFiles
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache

  def copy_ss_file(src_file)
    src_file = src_file.becomes_with_model
    klass = src_file.class
    dest_file = nil
    id = cache(:files, src_file.id) do
      Rails.logger.debug("#{src_file.filename}(#{src_file.id}): ファイルのコピーを開始します。")
      dest_file = klass.new(site_id: @dest_site.id)
      dest_file.attributes = copy_basic_attributes(src_file, klass)
      pseudo_file(src_file) do |tempfile|
        dest_file.in_file = tempfile
        dest_file.save!
      end

      FileUtils.mkdir_p File.dirname(dest_file.path)
      FileUtils.cp src_file.path, dest_file.path

      @task.log("#{src_file.filename}(#{src_file.id}): ファイルをコピーしました。")
      dest_file.id
    end
    dest_file ||= klass.where(site_id: @dest_site.id).find(id) if id
    dest_file
  rescue => e
    @task.log("#{src_file.filename}(#{src_file.id}): ファイルのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    raise
  end

  def resolve_file_reference(id)
    cache(:files, id) do
      src_file = SS::File.find(id) rescue nil
      if src_file.blank?
        Rails.logger.warn("#{id}: 参照されているファイルが存在しません。")
        return nil
      end

      dest_file = copy_ss_file(src_file)
      dest_file.try(:id)
    end
  end

  private

  def pseudo_file(src_file)
    base_file_data = ::File.open(src_file.path, 'rb:ASCII-8BIT')
    base_file_hash = {
      tempfile: base_file_data,
      filename: src_file.filename,
      type:     src_file.content_type,
      head:     pseudo_http_header(src_file)
    }
    yield ActionDispatch::Http::UploadedFile.new(base_file_hash)
  ensure
    base_file_data.close if base_file_data
  end

  def pseudo_http_header(src_file)
    headers = []
    headers << "Content-Disposition: form-data; name=\"item[in_files][]\"; filename=\"#{src_file.filename}\""
    headers << "Content-Type: #{src_file.content_type}"
    headers.join("\r\n")
  end
end
