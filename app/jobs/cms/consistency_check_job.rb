# 一貫性をチェックする。
# 長年運用してくと公開されてはいけないファイルが公開状態になったりする。
# このようなものをチェックし、可能であれば修復（このケースでは削除）する。
class Cms::ConsistencyCheckJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:consistency_check"

  def perform(*args)
    options = args.extract_options!
    @repair = options.fetch(:repair, false)

    deletable_fs_pathes_path = task.log_file_path.sub(".log", "") + "-deletable-fs-pathes.txt"
    FileUtils.mkdir_p(File.dirname(deletable_fs_pathes_path))
    @deletable_fs_pathes_file = File.open(deletable_fs_pathes_path, "wt")
    @deletable_fs_pathes_count = 0

    check_published_contents
    check_published_attachments

    if @deletable_fs_pathes_count > 0
      task.log("these #{@deletable_fs_pathes_count} files can delete")
      task.log("check #{deletable_fs_pathes_path} to see the all lists")
    else
      task.log("these are no files can delete")
    end
  ensure
    @deletable_fs_pathes_file.close if @deletable_fs_pathes_file
  end

  module Utils
    module_function

    def fs_path_to_id(path)
      path = path.sub(/^.*\/fs\//, "")
      path = path.sub(/\/_\/.+$/, "")
      path = path.delete("/")
      raise unless path.numeric?
      path.to_i
    end
  end

  private

  def check_published_contents
    # TODO: implements here
  end

  def fs_public_path
    @fs_public_path ||= "#{site.root_path}/fs"
  end

  def all_fs_files
    @all_fs_files ||= Dir.glob("#{fs_public_path}/**/*").select { FileTest.file?(_1) }
  end

  def file_id_to_fs_files_map
    @file_id_to_fs_files_map ||= all_fs_files.group_by { Utils.fs_path_to_id(_1) }
  end

  def find_owner_item(file)
    file.owner_item
  end

  def content_contained?(path)
    return true if Cms::Page.unscoped.where(contains_urls: /#{Regexp.escape(path)}/).exists?
    return true if Cms::Page.unscoped.where(value_contains_urls: /#{Regexp.escape(path)}/).exists?
    false
  end

  def check_published_attachments
    all_file_ids_in_fs = file_id_to_fs_files_map.keys
    task.log("found #{all_file_ids_in_fs.length} files in #{fs_public_path}")
    deletable_file_ids = Set.new
    all_file_ids_in_fs.each_slice(100) do |ids|
      files = SS::File.unscoped.in(id: ids).to_a
      id_to_file_map = files.index_by(&:id)
      ids.each do |id|
        file = id_to_file_map[id]
        if file.blank?
          task.log("file #{id} was deleted from database. this file can safely delete.")
          deletable_file_ids.add(id)
          file_id_to_fs_files_map[id].each { @deletable_fs_pathes_file.puts _1 }
          next
        end

        item = find_owner_item(file)
        if item.blank?
          task.log("file #{id} owner isn't found. this file can safely delete.")
          deletable_file_ids.add(id)
          file_id_to_fs_files_map[id].each { @deletable_fs_pathes_file.puts _1 }
          next
        end

        unless item.is_a?(Cms::Content)
          task.log("file #{id} owner isn't a content. I don't now whether this file can delete or not.")
          next
        end

        if item.site_id != site.id
          task.log("file #{id} owner is in a other site.")
          next
        end

        unless item.public?
          task.log("file #{id} owner isn't in public. this file can safely delete.")
          deletable_file_ids.add(id)
          file_id_to_fs_files_map[id].each { @deletable_fs_pathes_file.puts _1 }
          next
        end

        task.log("file #{id} owner is in public. this file cannot delete.")

        fs_files = file_id_to_fs_files_map[id]
        old_thumb_fs_files = fs_files.select { _1.include?("/thumb/") }
        next if old_thumb_fs_files.blank?

        old_thumb_fs_files.each do |old_thumb_fs_file|
          path = old_thumb_fs_file.sub(/^.*\/fs\//, "")
          next if content_contained?(path)

          task.log("there are no contents link to the url #{path}. #{old_thumb_fs_file} can safely delete.")
          @deletable_fs_pathes_file.puts(old_thumb_fs_file)
        end
      end
    end
  end
end
