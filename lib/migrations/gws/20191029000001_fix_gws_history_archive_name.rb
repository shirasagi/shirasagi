class SS::Migration20191029000001
  include SS::Migration::Base

  depends_on "20190301000001"

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
