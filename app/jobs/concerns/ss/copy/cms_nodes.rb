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
    @task.log("#{src_node.filename}(#{src_node.id}): フォルダーをコピーしました。")
  end
end
