module SS::Copy::CmsNodes
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_cms_node(src_node)
    copy_cms_content(:nodes, src_node, copy_cms_node_options)
  rescue => e
    @task.log("#{src_node.filename}(#{src_node.id}): フォルダーのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def resolve_node_reference(id)
    return nil if id.blank?

    cache(:nodes, id) do
      src_node = Cms::Node.site(@src_site).find(id) rescue nil
      if src_node.blank?
        Rails.logger.warn("#{id}: 参照されているフォルダーが存在しません。")
        return nil
      end

      dest_node = Cms::Node.site(@dest_site).where(filename: src_node.filename).first
      Rails.logger.info("resolve_node_reference: #{id} => #{dest_node.try(:id)}")
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
    when "rss/weather_xml"
      @task.log("#{src_node.filename}(#{src_node.id}): フォルダーのコピーをスキップします。")
      return
    end

    # summary_page_id の変換処理を追加 #issue5479 https://github.com/shirasagi/shirasagi/pull/5526
    if src_node.summary_page_id.present?
      new_summary_page_id = resolve_node_reference(src_node.summary_page_id)
      dest_node.update!(summary_page_id: new_summary_page_id) if new_summary_page_id
    else
      dest_node.update!(summary_page_id: nil)
    end

    @task.log("#{src_node.filename}(#{src_node.id}): フォルダーをコピーしました。")
  end
end
