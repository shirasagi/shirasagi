namespace :ss do
  task export_files_for_update: :environment do
    SS::File.all.each do |file|
      puts file.path
      next unless file[:file_id]

      begin
        dir = File.dirname(file.path)
        FileUtils.mkdir_p(dir) unless File.exists?(dir)

        fs = Mongoid::GridFs.get file[:file_id]
        File.binwrite file.path, fs.data
      rescue StandardError => e
        puts e.to_s
      end
    end
  end

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

  task set_pages_attached_file_attributes: :environment do
    ids = Cms::Page.pluck(:id)
    ids.each do |id|
      item = Cms::Page.find(id).becomes_with_route rescue nil
      next unless item
      next unless item.class.include?(Cms::AttachedFiles)
      next if item.attached_files.blank?

      puts "#{id} #{item.name}"

      attrs = item.attached_files.map do |file|
        attr = Cms::AttachedFileAttribute.new
        attr.page_id = item.id
        attr.initialize_from_file(file)
        attr
      end
      item.set(attached_file_attributes: attrs)
    end
  end
end
