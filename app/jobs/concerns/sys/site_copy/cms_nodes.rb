module Sys::SiteCopy::CmsNodes
  extend ActiveSupport::Concern
  include SS::Copy::CmsNodes
  include Sys::SiteCopy::CmsContents

  def copy_cms_nodes
    node_ids = Cms::Node.site(@src_site).pluck(:id)
    node_ids.each do |node_id|
      node = Cms::Node.site(@src_site).find(node_id) rescue nil
      next if node.blank?
      Rails.logger.debug("♦︎ [copy_cms_nodes] #{node.filename}:" \
                         "コピー開始 (summary_page_id=#{node.try(:summary_page_id)})")
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

      Rails.logger.debug("♦︎ [resolve_node_reference] #{src_node.filename}:" \
                         "解決開始 (summary_page_id=#{src_node.try(:summary_page_id)})")
      dest_node = copy_cms_node(src_node)
      Rails.logger.debug("♦︎ [resolve_node_reference] #{src_node.filename} → #{dest_node.try(:filename)}:" \
                         "解決完了 (summary_page_id=#{dest_node.try(:summary_page_id)})")
      dest_node.try(:id)
    end
  end

  private

  def copy_node_files(src_node, dest_node)
    # ディレクトリ複製
    src_dir_path = @src_site.path + '/' + src_node.filename
    dest_dir_path = @dest_site.path + '/' + dest_node.filename

    return unless Dir.exist?(src_dir_path)

    ::FileUtils.mkdir_p dest_dir_path
    Dir.entries(src_dir_path).each do |filename|
      next if %w(. ..).include?(filename)
      src_file_path = src_dir_path + '/' + filename
      next unless File.exist?(src_file_path)

      Rails.logger.debug("#{src_file_path}: ファイルをコピーします。")
      ::FileUtils.cp_r(src_file_path, dest_dir_path)
      Rails.logger.info("#{src_file_path}: ファイルをコピーしました。")
    end
  end

  def copy_inquiry_columns(src_node, dest_node)
    Inquiry::Column.where(site_id: @src_site.id, node_id: src_node.id).order_by(updated: 1).each do |src_inquiry_column|
      Rails.logger.debug("#{src_inquiry_column.name}(#{src_inquiry_column.id}): Inquiry::Column をコピーします。")
      dest_inquiry_column = Inquiry::Column.new src_inquiry_column.
        attributes.except("id", "_id", "node_id", "site_id", "created", "updated")
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
          attributes.except("id", "_id", "node_id", "site_id", "created", "updated")
      dest_ezine_column.cur_site = @dest_site
      dest_ezine_column.site_id = @dest_site.id
      dest_ezine_column.cur_node = dest_node
      dest_ezine_column.node_id = dest_node.id
      dest_ezine_column.save!
      Rails.logger.info("#{src_ezine_column.name}(#{src_ezine_column.id}): Ezine::Column をコピーしました。")
    end
  end
end
