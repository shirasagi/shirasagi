class SS::Migration20220215000000
  include SS::Migration::Base

  depends_on "20211110000000"

  ARRAY_FIELDS = [
    :contains_urls, :value_contains_urls, :form_contains_urls
  ].freeze

  def change
    criteria = Cms::Page.all.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |page|
        next unless page.site

        attributes = {}
        ARRAY_FIELDS.each do |key|
          next if page.try(key).blank?

          attributes[key] = page[key].collect { |c| c.try(:strip) }.compact
          page[key] = attributes[key]
        end

        page.set(attributes) if page.changed?

        next if page.try(:column_values).blank?

        page.column_values.each do |column_value|
          attributes = {}
          ARRAY_FIELDS.each do |key|
            next if column_value.try(key).blank?

            attributes[key] = column_value[key].collect(&:strip)
            column_value[key] = attributes[key]
          end

          column_value.set(attributes) if column_value.changed?
        end
      end
    end
  end
end
