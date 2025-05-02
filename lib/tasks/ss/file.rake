namespace :ss do
  task set_files_csv_headers: :environment do
    ids = SS::File.pluck(:id)
    ids.each do |id|
      item = SS::File.find(id) rescue nil
      next unless item
      next unless item.csv_or_xlsx?

      puts "#{id} #{item.filename}"

      item.send(:extract_csv_headers, item)
      if item.csv_headers.present?
        item.set(csv_headers: item.csv_headers)
      end
    end
  end
end
