module SS::Copy::CmsForms
  extend ActiveSupport::Concern
  include SS::Copy::Cache

  def copy_cms_form(src_item)
    model = Cms::Form
    dest_item = nil
    options = copy_cms_form_options
    id = cache(:forms, src_item.id) do
      options[:before].call(src_item) if options[:before]
      dest_item = model.new(cur_site: @dest_site)
      dest_item.attributes = copy_basic_attributes(src_item, model)
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
    @task.log("#{src_item.name}(#{src_item.id}): 定型フォームのコピーに失敗しました。")
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end

  def copy_cms_forms
    model = Cms::Form
    model.site(@src_site).pluck(:id).each do |id|
      item = model.site(@src_site).find(id) rescue nil
      next if item.blank?
      copy_cms_form(item)
    end
  end

  def resolve_form_reference(id)
    id
  end

  private

  def copy_cms_form_options
    {
      before: method(:before_copy_cms_form),
      after: method(:after_copy_cms_form)
    }
  end

  def before_copy_cms_form(src_item)
    Rails.logger.debug("#{src_item.name}(#{src_item.id}): 定型フォームのコピーを開始します。")
  end

  def after_copy_cms_form(src_item)
    @task.log("#{src_item.name}(#{src_item.id}): 定型フォームをコピーしました。")
  end
end
