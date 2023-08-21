class SS::Migration20190809000000
  include SS::Migration::Base

  depends_on "20190717000000"

  def change
    each_file do |file|
      # 全履歴の uploadfile_srcname が "history-1" の場合は修復可能。
      # uploadfile_srcname に "history0" や "history1" などが混じっている場合は、修復不可能。
      src_names = file.histories.pluck(:uploadfile_srcname).uniq
      next unless src_names.all? { |src_name| src_name == "history-1" }

      dirname = ::File.dirname(file.path)
      ::Fs.cp(file.path, "#{dirname}/#{file.id}_history0")
      file.histories.set(uploadfile_srcname: "history0")
    end
  end

  def each_file(&block)
    criteria = Gws::Share::File.all
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      files = criteria.in(id: ids).to_a
      files.each(&block)
    end
  end
end
