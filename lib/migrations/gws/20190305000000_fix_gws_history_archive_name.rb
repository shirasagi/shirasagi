class SS::Migration20190305000000
  def change
    all_ids = Gws::HistoryArchiveFile.all.pluck(:id).sort
    all_ids.each_slice(20) do |ids|
      Gws::HistoryArchiveFile.all.in(id: ids).to_a.each do |file|
        ext = ::File.extname(file.name)
        next if ext.present?
        file.set(name: "#{file.name}#{::File.extname(file.filename)}")
      end
    end
  end
end
