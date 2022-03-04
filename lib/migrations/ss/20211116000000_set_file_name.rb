class SS::Migration20211116000000
  include SS::Migration::Base

  depends_on "20211021000000"

  def change
    each_file do |file|
      file.set(name: SS::FilenameUtils.convert_to_url_safe_japanese(file.basename))
    end
  end

  private

  def each_file(&block)
    criteria = SS::File.all.exists(name: false)
    all_ids = criteria.pluck(:id)
    SS::File.each_file(all_ids, &block)
  end
end
