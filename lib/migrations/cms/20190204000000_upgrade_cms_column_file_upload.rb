class SS::Migration20190204000000
  def change
    all_ids = Cms::Form.pluck(:id)
    all_ids.each_slice(20) do |ids|
      Cms::Form.in(id: ids).to_a.each do |item|
        item.columns.each do |column|
          next unless column._type == "Cms::Column::FileUpload"
          next if column.file_type.present?
          case column.html_tag
          when "a+img"
            column.file_type = "image"
          when "img"
            column.file_type = "image"
            column.layout = '<img src="{{ value.file.url }}" alt="{{ value.image_text | default: value.file.humanized_name }}" />'
          when "a"
            column.file_type = "attachment"
          end
          column.save
        end
      end
    end
  end
end
