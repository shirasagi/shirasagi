class SS::Migration20181128000000
  include SS::Migration::Base

  depends_on "20181126000000"

  def change
    all_ids = Cms::Form.pluck(:id)
    all_ids.each_slice(20) do |ids|
      Cms::Form.in(id: ids).to_a.each do |item|
        html = item.html
        next if html.blank?
        next if !html.include?("{{")

        updated_html = html.gsub(/\{\{(.+)\}\}/) do
          name_or_id = $1.strip
          if name_or_id.include?("values") || name_or_id.include?("[") || name_or_id.include?(".") || name_or_id.include?("|")
            "{{ #{name_or_id} }}"
          else
            # update to liquid format
            "{{ values[\"#{name_or_id}\"] }}"
          end
        end

        next if updated_html == html

        item.set(html: updated_html)
      end
    end
  end
end
