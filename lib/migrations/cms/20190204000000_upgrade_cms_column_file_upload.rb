class SS::Migration20190204000000
  def change
    all_ids = Cms::Form.pluck(:id)
    all_ids.each_slice(20) do |ids|
      Cms::Form.in(id: ids).to_a.each do |item|
        item.columns.each do |column|
          next unless column._type == "Cms::Column::FileUpload"
          case column.html_tag
          when "img", "a+img"
            column.file_type = "image"
          when "a"
            column.file_type = "attachment"
          end
          column.save
        end
      end
    end
  end
end
