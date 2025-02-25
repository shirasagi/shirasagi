module SS::Copy::CmsNodes
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_cms_node(src_node)
    Rails.logger.debug do
      "SS::Copy::CmsNodes[copy_cms_node] #{src_node.filename}: " \
        "コピー処理開始 (summary_page_id=#{src_node.try(:summary_page_id)})"
    end
    copy_cms_content(:nodes, src_node, copy_cms_node_options)
  rescue => e
    @task.log("#{src_node.filename}(#{src_node.id}): フォルダーのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def resolve_node_reference(id)
    id
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
    Rails.logger.debug{ "[after_copy_cms_node] #{src_node.filename}: 処理前 summary_page_id=#{src_node.try(:summary_page_id)}" }
    Rails.logger.debug{ "[after_copy_cms_node] #{src_node.filename}: 処理前 summary_page=#{src_node.try(:summary_page).inspect}" }
    case src_node.route
    when "uploader/file"
      copy_node_files(src_node, dest_node)
    when "inquiry/form"
      copy_inquiry_columns(src_node, dest_node)
    when "ezine/page"
      copy_ezine_columns(src_node, dest_node)
    when "category/page"
      dest_node.summary_page_id = nil unless @copy_contents.include?('pages')
      dest_node.save!
    when "rss/weather_xml"
      @task.log("#{src_node.filename}(#{src_node.id}): フォルダーのコピーをスキップします。")
      return
    end

    @task.log("#{src_node.filename}(#{src_node.id}): フォルダーをコピーしました。")
    Rails.logger.debug do
      "[after_copy_cms_node] #{src_node.filename} → #{dest_node.try(:filename)}:" \
        "コピー処理完了 (summary_page_id=#{dest_node.try(:summary_page_id)})"
    end
    Rails.logger.debug do
      "[after_copy_cms_node] #{src_node.filename}: → #{dest_node.try(:filename)}:" \
        "コピー処理完了 (summary_page=#{dest_node.try(:summary_page).inspect}"
    end
  end
end
