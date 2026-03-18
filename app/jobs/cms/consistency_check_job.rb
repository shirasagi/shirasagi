# 一貫性をチェックする。
# 長年運用してくと公開されてはいけないファイルが公開状態になったりする。
# このようなものをチェックし、可能であれば修復（このケースでは削除）する。
class Cms::ConsistencyCheckJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Cms::Task
  self.task_name = "cms:consistency_check"

  class ListFile
    include ActiveModel::Model

    attr_accessor :path

    def append(path)
      io.puts path
      @count += 1
    end

    def count
      @count || 0
    end

    def close
      @io.close if @io
      @io = nil
    end

    private

    def io
      @io ||= begin
        FileUtils.mkdir_p(File.dirname(path))
        @count = 0
        File.open(path, "wt")
      end
    end
  end

  def perform(*args)
    options = args.extract_options!

    deletable_pathes_path = task.log_file_path.sub(".log", "") + "-deletable-pathes.txt"
    @list_file = ListFile.new(path: deletable_pathes_path)

    check_published_contents
    check_published_attachments

    if @list_file.count > 0
      task.log("these #{@list_file.count} files can delete")
      task.log("check #{deletable_pathes_path} to see the all lists")
    else
      task.log("these are no files can delete")
    end

    @list_file.close

    return unless options.fetch(:repair, false)
    return if @list_file.count == 0

    repair_all(deletable_pathes_path)
  ensure
    @list_file.close if @list_file
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

    def recognize_node(site, node, path)
      path = path.sub(/\.p\d+\.html$/, ".html") if path.match?(/\.p[1-9]\d*\.html$/)
      action = path.sub(/^#{::Regexp.escape(node.filename)}/, "")

      rest = action.delete_suffix("index.html")
      rest = action if ::File.extname(rest).present?

      path = "/.s#{site.id}/nodes/#{node.route}#{rest}"
      recognize_agent path
    end

    def recognize_agent(path, env = {})
      spec = recognize_path path, env
      spec[:cell] ? spec : nil
    end

    def recognize_path(path, env = {})
      env[:method] ||= request.request_method rescue "GET"
      Rails.application.routes.recognize_path(path, env) rescue {}
    end
  end

  private

  def check_published_contents
    if site.same_domain_sites.length == 1
      html_files_in_site = all_html_files
    else
      # サブサイトのコンテンツを除外
      html_files_in_site = all_html_files.select { site.same_domain_site_from_path("/#{_1}").try(:id) == site.id }
    end
    task.log("found #{html_files_in_site.length} html files in '#{site.path}'")
    return if html_files_in_site.blank?

    all_pages = Cms::Page.unscoped.site(site).in(filename: html_files_in_site).to_a
    filenames_in_page = Set.new(all_pages.pluck(:filename))
    html_files_page, html_files_not_page = html_files_in_site.partition { filenames_in_page.include?(_1) }

    filename_to_page_map = all_pages.index_by(&:filename)
    html_files_page.each do |path|
      page = filename_to_page_map[path]
      next if page.public?

      task.log("'#{site.path}/#{path}' is matched page '#{page.filename}' which isn't in public. this file can delete.")
      @list_file.append("#{site.path}/#{path}")
    end

    html_files_not_page.each do |path|
      node = find_node_in_path(path)
      if node.blank?
        task.log("'#{site.path}/#{path}' doesn't match pages nor nodes. this file can delete.")
        @list_file.append("#{site.path}/#{path}")
        next
      end

      if node.route == 'uploader/file'
        # task.log("'#{path}' is just one of uploader contents. this means this file is unmanaged so I don't know anymore.")
        next
      end

      spec = Utils.recognize_node(site, node, path)
      next if spec.present?

      task.log("'#{site.path}/#{path}' is matched node '#{node.filename}' which cannot serve. this file can delete.")
      @list_file.append("#{site.path}/#{path}")
    end
  end

  def all_html_files
    @all_html_files ||= begin
      paths = Dir.glob("#{site.path}/**/*.html").select { FileTest.file?(_1) }
      paths.map! { _1.sub("#{site.path}/", "") }
      paths.sort!
      paths
    end
  end

  def all_nodes
    @all_nodes ||= Cms::Node.unscoped.site(site).to_a
  end

  def filename_to_node_map
    @filename_to_node_map ||= all_nodes.index_by(&:filename)
  end

  def find_node_in_path(path)
    paths = Cms::Node.split_path(path.sub(/^\//, ""))
    paths.pop if paths.last =~ /\./
    paths = paths.sort_by { _1.count("/") }.reverse
    paths.filter_map { filename_to_node_map[_1] }.first
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
          file_id_to_fs_files_map[id].each { @list_file.append _1 }
          next
        end

        item = find_owner_item(file)
        if item.blank?
          task.log("file #{id} owner isn't found. this file can safely delete.")
          deletable_file_ids.add(id)
          file_id_to_fs_files_map[id].each { @list_file.append _1 }
          next
        end

        unless item.is_a?(Cms::Content)
          # task.log("file #{id} owner isn't a content. I don't now whether this file can delete or not.")
          next
        end

        if item.site_id != site.id
          # task.log("file #{id} owner is in a other site.")
          next
        end

        unless item.public?
          task.log("file #{id} owner isn't in public. this file can safely delete.")
          deletable_file_ids.add(id)
          file_id_to_fs_files_map[id].each { @list_file.append _1 }
          next
        end

        # task.log("file #{id} owner is in public. this file cannot delete.")

        fs_files = file_id_to_fs_files_map[id]
        old_thumb_fs_files = fs_files.select { _1.include?("/thumb/") }
        next if old_thumb_fs_files.blank?

        old_thumb_fs_files.each do |old_thumb_fs_file|
          path = old_thumb_fs_file.sub(/^.*\/fs\//, "")
          next if content_contained?(path)

          task.log("there are no contents link to the url #{path}. #{old_thumb_fs_file} can safely delete.")
          @list_file.append(old_thumb_fs_file)
        end
      end
    end
  end

  def repair_all(list_file_path)
    File.foreach(list_file_path) do |path|
      path.strip!
      File.unlink(path)
      task.log("#{path}: deleted")
    end
  end
end
