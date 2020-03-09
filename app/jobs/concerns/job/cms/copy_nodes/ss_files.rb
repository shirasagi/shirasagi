module Job::Cms::CopyNodes::SsFiles
  extend ActiveSupport::Concern
  include SS::Copy::SsFiles

  def copy_ss_file(src_file)
    src_file = src_file.becomes_with_model
    klass = src_file.class
    dest_file = nil
    id = cache(:files, src_file.id) do
      Rails.logger.debug("#{src_file.filename}(#{src_file.id}): ファイルのコピーを開始します。")
      dest_file_attributes = copy_basic_attributes(src_file, klass)
      dest_file_attributes[:site_id] = @cur_site.id
      dest_file = klass.create_empty!(dest_file_attributes) do |file|
        ::FileUtils.copy(src_file.path, file.path)
      end

      @task.log("#{dest_file.filename}(#{dest_file.id}): ファイルをコピーしました。")
      dest_file.id
    end
    dest_file ||= klass.where(site_id: @cur_site.id).find(id) if id
    dest_file
  rescue => e
    @task.log("#{src_file.filename}(#{src_file.id}): ファイルのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    raise
  end
end
