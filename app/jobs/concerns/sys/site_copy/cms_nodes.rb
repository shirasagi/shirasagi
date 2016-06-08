module Sys::SiteCopy::CmsNodes
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Sys::SiteCopy::CmsContents

  def copy_cms_node(src_node)
    src_node = src_node.becomes_with_route
    copy_cms_content(:nodes, src_node, copy_cms_node_options)
  rescue => e
    @task.log("#{src_node.filename}(#{src_node.id}): フォルダーのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_nodes
    Cms::Node.site(@src_site).each do |node|
      copy_cms_node(node)
    end
  end

  def resolve_node_reference(id)
    cache(:nodes, id) do
      src_node = Cms::Node.site(@src_site).find(id) rescue nil
      if src_node.blank?
        Rails.logger.warn("#{id}: 参照されているフォルダーが存在しません。")
        return nil
      end

      dest_node = copy_cms_node(src_node)
      dest_node.try(:id)
    end
  end

  private

  def copy_cms_node_options
    {
      before: method(:before_copy_cms_node),
      after: method(:after_copy_cms_node),
    }
  end

  def before_copy_cms_node(src_node)
    Rails.logger.debug("#{src_node.filename}(#{src_node.id}): フォルダーのコピーを開始します。")
  end

  def after_copy_cms_node(src_node, dest_node)
    case src_node.route
    when "uploader/file"
      copy_node_files(src_node, dest_node)
    when "inquiry/form"
      copy_inquiry_columns(src_node, dest_node)
    when "ezine/page"
      copy_ezine_columns(src_node, dest_node)
    end

    @task.log("#{src_node.filename}(#{src_node.id}): フォルダーをコピーしました。")
  end

  def copy_node_files(src_node, dest_node)
    # ディレクトリ複製
    src_dir_path = @src_site.path + '/' + src_node.filename
    dest_dir_path = @dest_site.path + '/' + dest_node.filename

    return unless Dir.exist?(src_dir_path)

    ::FileUtils.mkdir_p dest_dir_path
    Dir.entries(src_dir_path).each do |filename|
      next if %w(. ..).include?(filename)
      next unless File.exist?(src_dir_path + '/' + filename)
      next if Dir.exist?(src_dir_path + '/' + filename)

      Rails.logger.debug("#{src_dir_path + '/' + filename}: ファイルをコピーします。")
      ::FileUtils.cp(src_dir_path + '/' + filename, dest_dir_path)
      Rails.logger.info("#{src_dir_path + '/' + filename}: ファイルをコピーしました。")
    end
  end

  def copy_inquiry_columns(src_node, dest_node)
    Inquiry::Column.where(site_id: @src_site.id, node_id: src_node.id).order_by(updated: 1).each do |src_inquiry_column|
      Rails.logger.debug("#{src_inquiry_column.name}(#{src_inquiry_column.id}): Inquiry::Column をコピーします。")
      dest_inquiry_column = Inquiry::Column.new src_inquiry_column.
        attributes.except(:id, :_id, :node_id, :site_id, :created, :updated)
      dest_inquiry_column.cur_site = @dest_site
      dest_inquiry_column.site_id = @dest_site.id
      # dest_inquiry_column.cur_node = dest_node
      dest_inquiry_column.node_id = dest_node.id
      dest_inquiry_column.save!
      Rails.logger.info("#{src_inquiry_column.name}(#{src_inquiry_column.id}): Inquiry::Column をコピーしました。")
    end
  end

  def copy_ezine_columns(src_node, dest_node)
    Ezine::Column.where(site_id: @src_site.id, node_id: src_node.id).order_by(updated: 1).each do |src_ezine_column|
      Rails.logger.debug("#{src_ezine_column.name}(#{src_ezine_column.id}): Ezine::Column をコピーします。")
      dest_ezine_column = Ezine::Column.new src_ezine_column.
          attributes.except(:id, :_id, :node_id, :site_id, :created, :updated)
      dest_ezine_column.cur_site = @dest_site
      dest_ezine_column.site_id = @dest_site.id
      dest_ezine_column.cur_node = dest_node
      dest_ezine_column.node_id = dest_node.id
      dest_ezine_column.save!
      Rails.logger.info("#{src_ezine_column.name}(#{src_ezine_column.id}): Ezine::Column をコピーしました。")
    end
  end
end
