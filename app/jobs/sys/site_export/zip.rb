class Sys::SiteExport::Zip
  include ActiveModel::Model

  attr_accessor :path, :output_dir, :site_dir, :exclude_public_files, :task

  # zip にコミットせずに延々とファイルを追加していくと、際限なくメモリーを消費してしまう。
  # 適度にコミットすることでメモリー消費を抑える。
  #
  # zip に 100 ファイル以上 追加したら、zip をコミット
  THRESHOLD_COUNT = 100
  # zip に 100 MB以上 追加したら、zip をコミット
  THRESHOLD_BYTES = 100 * 1_024 * 1_024

  def compress
    task_log "-- archive \"#{@output_dir}/\" and \"#{@site_dir}\" to \"#{@path}\""

    Zip::File.open(@path, Zip::File::CREATE) do |zip|
      added_count = 0
      added_bytes = 0
      each_file do |src_file, dest_file|
        if File.directory?(src_file)
          zip.mkdir(dest_file)
        else
          zip.add(::Fs.zip_safe_path(dest_file), src_file)
          added_count += 1
          added_bytes += ::File.size(src_file)

          if added_count > THRESHOLD_COUNT || added_bytes > THRESHOLD_BYTES
            zip.commit
            added_count = 0
            added_bytes = 0
          end
        end
      end
    end
  end

  private

  def task_log(msg)
    if @task
      @task.log msg
    end
  end

  def each_file(&block)
    require "find"

    enumerators = []

    source_files = Find.find(@output_dir).lazy
    path_prefix = "#{@output_dir}/"
    source_files = source_files.map { |src_file| [ src_file, src_file[path_prefix.length..-1] ] }
    source_files = source_files.select { |_src_file, dest_file| dest_file.present? }
    enumerators << source_files

    if FileTest.directory?(@site_dir)
      pub_files = Find.find(@site_dir).lazy
      pub_files = pub_files.reject { |src_file| excluded_public?(src_file) }
      pub_files = pub_files.map { |src_file| [ src_file, src_file.sub(/^#{@site_dir}/, 'public') ] }
      enumerators << pub_files
    end

    file_counts = enumerators.map(&:count)
    task_log "-- found #{file_counts.map { |v| v.to_s(:delimited) }.join(" + ")} files/directories to archive"

    all_file_count = file_counts.sum
    reported_at = Time.zone.now.to_i
    completed_count = 0
    enumerators.each do |enumerator|
      enumerator.each_slice(10) do |src_dest_pairs|
        src_dest_pairs.each(&block)
        completed_count += src_dest_pairs.length

        if Time.zone.now.to_i - reported_at > 60
          task_log "-- #{completed_count.to_s(:delimited)} / #{all_file_count.to_s(:delimited)}"
          reported_at = Time.zone.now.to_i
        end
      end
    end

    task_log "-- #{completed_count.to_s(:delimited)} / #{all_file_count.to_s(:delimited)}"
  end

  def site_fs_path
    @_site_fs_path ||= begin
      site_dir ? ::File.join(site_dir, "fs/") : ""
    end
  end

  def excluded_public?(path)
    return true if path.start_with?(site_fs_path)
    return true if @exclude_public_files.include?(path)
    false
  end
end
