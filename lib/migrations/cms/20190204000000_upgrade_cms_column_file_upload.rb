class SS::Migration20190204000000
  include SS::Migration::Base

  depends_on "20190116000000"

  def change
    all_ids = Cms::Form.pluck(:id)
    all_ids.each_slice(20) do |ids|
      Cms::Form.in(id: ids).to_a.each do |item|
        item.columns.each do |column|
          next unless column._type == "Cms::Column::FileUpload"
          next if column.file_type.present?
          case column.html_tag
          when "img"
            column.file_type = "image"
            column.layout = '<img src="{{ value.file.url }}" alt="{{ value.file_label | default: value.file.humanized_name }}" />'
          when "a"
            column.file_type = "attachment"
          else # "a+img"
            column.file_type = "image"
          end
          column.without_record_timestamps { column.save }
        end
      end
    end
  end
end
