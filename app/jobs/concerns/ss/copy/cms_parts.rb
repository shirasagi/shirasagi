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
    if dest_part.respond_to?(:condition_forms) && dest_part.condition_forms.values.present?
      condition_forms = []
      dest_part.condition_forms.each do |dest_condition_form|
        form_id = resolve_reference(:form, dest_condition_form.form_id)
        filters = []
        dest_condition_form.filters.each do |filter|
          filters << filter.to_h.merge(column_id: resolve_reference(:column, filter.column_id))
        end
        condition_forms << dest_condition_form.to_h.merge(form_id: form_id, filters: filters)
      end
      dest_part.condition_forms = condition_forms
      dest_part.save!
    end

    @task.log("#{src_part.filename}(#{src_part.id}): パーツをコピーしました。")
  end
end
