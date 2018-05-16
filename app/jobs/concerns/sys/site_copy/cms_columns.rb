module Sys::SiteCopy::CmsColumns
  extend ActiveSupport::Concern
  include Sys::SiteCopy::Cache
  include Sys::SiteCopy::CmsContents

  def copy_cms_column(src_item)
    model = Cms::Column::Base
    dest_item = nil
    options = copy_cms_column_options
    id = cache(:forms, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = copy_basic_attributes(src_item, model)
      dest_item.form_id = resolve_reference(:form, src_item.form_id)
      dest_item.save!
      dest_item.id
    end

    if dest_item
      dest_item.attributes = resolve_unsafe_references(src_item, model)
      dest_item.save!

      options[:after].call(src_item) if options[:after]
    end

    dest_item ||= model.site(@dest_site).find(id) if id
    dest_item
  rescue => e
    @task.log("#{src_item.name}(#{src_item.id}): 入力項目のコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_columns
    model = Cms::Column::Base
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_cms_column(item)
    end
  end

  def resolve_column_reference(id)
    cache(:columns, id) do
      src_item = Cms::Column::Base.site(@src_site).find(id) rescue nil
      if src_item.blank?
        Rails.logger.warn("#{id}: 参照されている入力項目が存在しません。")
        return nil
      end

      dest_item = copy_cms_column(src_item)
      dest_item.try(:id)
    end
  end

  private

  def copy_cms_column_options
    {
      before: method(:before_copy_cms_column),
      after: method(:after_copy_cms_column)
    }
  end

  def before_copy_cms_column(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): 入力項目のコピーを開始します。")
  end

  def after_copy_cms_column(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): 入力項目をコピーしました。")
  end
end
