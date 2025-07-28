# 空ディレクトリの削除
class SS::DeleteEmptyDirectoriesJob < SS::ApplicationJob
  TARGET_DIRECTORIES = %w(job_logs ss_files ss_tasks).freeze

  def perform
    TARGET_DIRECTORIES.each do |dir|
      path = "#{Rails.root}/private/files/#{dir}"
      system("find #{path} -type d -empty -delete") if ::Dir.exist?(path)
    end
  end
end
