module Job::Cms::CopyNodes::CmsNodes
  extend ActiveSupport::Concern
  include SS::Copy::CmsNodes
  include Job::Cms::CopyNodes::CmsContents

  def copy_cms_nodes
    Cms::Node.site(@cur_site).where(filename: /^#{@cur_node.filename}\/|^#{@cur_node.filename}$/).each do |node|
      copy_cms_node(node)
    end
  end

  private

  def copy_node_files(src_node, dest_node)
    # ディレクトリ複製
    src_dir_path = src_node.site.path + '/' + src_node.filename
    dest_dir_path = dest_node.site.path + '/' + dest_node.filename

    return unless Dir.exist?(src_dir_path)

    ::FileUtils.mkdir_p dest_dir_path
    Dir.entries(src_dir_path).each do |filename|
      next if %w(. ..).include?(filename)
      next unless File.exist?(src_dir_path + '/' + filename)
      next if Dir.exist?(src_dir_path + '/' + filename)

      @task.log("#{src_dir_path + '/' + filename}: ファイルをコピーします。")
      ::FileUtils.cp(src_dir_path + '/' + filename, dest_dir_path)
      @task.log("#{src_dir_path + '/' + filename}: ファイルをコピーしました。")
    end
  end

  def copy_inquiry_columns(src_node, dest_node)
    Inquiry::Column.where(site_id: src_node.site_id, node_id: src_node.id).order_by(updated: 1).each do |src_inquiry_column|
      @task.log("#{src_inquiry_column.name}(#{src_inquiry_column.id}): Inquiry::Column をコピーします。")
      dest_inquiry_column = Inquiry::Column.new src_inquiry_column.
        attributes.except(:id, :_id, :node_id, :site_id, :created, :updated)

      dest_inquiry_column.site_id = dest_node.site_id
      dest_inquiry_column.node_id = dest_node.id
      dest_inquiry_column.save!
      @task.log("#{src_inquiry_column.name}(#{src_inquiry_column.id}): Inquiry::Column をコピーしました。")
    end
  end

  def copy_ezine_columns(src_node, dest_node)
    Ezine::Column.where(site_id: src_node.site_id, node_id: src_node.id).order_by(updated: 1).each do |src_ezine_column|
      @task.log("#{src_ezine_column.name}(#{src_ezine_column.id}): Ezine::Column をコピーします。")
      dest_ezine_column = Ezine::Column.new src_ezine_column.
          attributes.except(:id, :_id, :node_id, :site_id, :created, :updated)
      dest_ezine_column.site_id = dest_node.site_id
      dest_ezine_column.node_id = dest_node.id
      dest_ezine_column.save!
      @task.log("#{dest_ezine_column.name}(#{dest_ezine_column.id}): Ezine::Column にコピーしました。")
    end
  end
end
