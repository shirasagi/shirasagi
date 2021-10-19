class Cms::Column::Value::SelectPage < Cms::Column::Value::Base
  belongs_to :page, class_name: "Cms::Page"
  permit_values :page_id, :text

  liquidize do
    export :page
    export :page_link
  end

  def value
    page.try(:name)
  end

  def page_link
    return unless page
    ApplicationController.helpers.link_to(page.name, page.url)
  end

  def import_csv(values)
    values.map do |name, value|
      case name
      when self.class.t(:alignment)
        self.alignment = value.present? ? I18n.t("cms.options.alignment").invert[value] : nil
      when self.class.t(:page_id)
        if value.present?
          id = value.scan(/\((\d+?)\)$/).flatten.first.to_i
          page = Cms::Page.find(id) rescue nil
          self.page_id = page.id if page
        else
          self.page = nil
        end
      end
    end
  end

  private

  def to_default_html
    page_link
  end

  def validate_value
    return if column.blank?

    if column.required? && page.nil?
      self.errors.add(:page_id, :blank)
    end
    if page && !column.page_ids.include?(page_id)
      self.errors.add(:page_id, :inclusion)
    end
  end
end
