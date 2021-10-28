module SS::Copy::CmsParts
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_cms_part(src_part)
    copy_cms_content(:parts, src_part, copy_cms_part_options)
  rescue => e
    @task.log("#{src_part.filename}(#{src_part.id}): パーツのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def resolve_part_reference(id)
    id
  end

  private

  def copy_cms_part_options
    {
      before: method(:before_copy_cms_part),
      after: method(:after_copy_cms_part)
    }
  end

  def before_copy_cms_part(src_part)
    Rails.logger.debug("#{src_part.filename}(#{src_part.id}): パーツのコピーを開始します。")
  end

  def after_copy_cms_part(src_part, dest_part)
    @task.log("#{src_part.filename}(#{src_part.id}): パーツをコピーしました。")
  end
end
