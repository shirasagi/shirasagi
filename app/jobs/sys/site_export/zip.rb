class Sys::SiteExport::Zip
  include ActiveModel::Model

  attr_accessor :path, :output_dir, :site_dir, :exclude_public_files, :task

  def compress
    task_log "-- archive \"#{@output_dir}/\" and \"#{@site_dir}\" to \"#{@path}\""

    entry_set = Set.new
    comment = "shirasagi #{SS.version} site export data created at #{Time.zone.now.iso8601}"
    SS::Zip::Writer.create(@path, comment: comment) do |zip|
      each_file do |src_file, dest_file|
        next unless ::File.file?(src_file)

        name = ::Fs.zip_safe_path(dest_file)
        if entry_set.include?(name)
          task_log "Entry #{dest_file} already exists"
        end

        zip.add_file(name) do |output|
          ::IO.copy_stream(src_file, output)
        end
        entry_set.add(name)
      end
    end
  end

  private

  def task_log(msg)
    if @task
      @task.log msg
    else
      Rails.logger.info(msg)
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
    task_log "-- found #{file_counts.map { |v| v.to_fs(:delimited) }.join(" + ")} files/directories to archive"

    all_file_count = file_counts.sum
    reported_at = Time.zone.now.to_i
    completed_count = 0
    enumerators.each do |enumerator|
      enumerator.each_slice(10) do |src_dest_pairs|
        src_dest_pairs.each(&block)
        completed_count += src_dest_pairs.length

        if Time.zone.now.to_i - reported_at > 60
          task_log "-- #{completed_count.to_fs(:delimited)} / #{all_file_count.to_fs(:delimited)}"
          reported_at = Time.zone.now.to_i
        end
      end
    end
  ensure
    task_log "-- finished #{completed_count.to_fs(:delimited)} / #{all_file_count.to_fs(:delimited)}"
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
