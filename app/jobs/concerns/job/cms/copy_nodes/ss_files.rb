module Job::Cms::CopyNodes::SsFiles
  extend ActiveSupport::Concern
  include Sys::SiteCopy::SsFiles

  def copy_ss_file(src_file)
    src_file = src_file.becomes_with_model
    klass = src_file.class
    dest_file = nil
    id = cache(:files, src_file.id) do
      @task.log("#{src_file.filename}(#{src_file.id}): ファイルのコピーを開始します。")
      dest_file = klass.new(site_id: @cur_site.id)
      dest_file.attributes = copy_basic_attributes(src_file, klass)
      pseudo_file(src_file) do |tempfile|
        dest_file.in_file = tempfile
        dest_file.save!
      end

      FileUtils.mkdir_p File.dirname(dest_file.path)
      FileUtils.cp src_file.path, dest_file.path

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
