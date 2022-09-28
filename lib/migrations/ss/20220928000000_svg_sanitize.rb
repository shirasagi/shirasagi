class SS::Migration20220928000000
  include SS::Migration::Base

  depends_on "20220824000000"

  def change
    each_file do |file|
      SS::File.sanitize_svg(file)
      file.set(size: file.size)
    end
  end

  private

  def each_file(&block)
    criteria = SS::File.all.where(content_type: SS::File::SVG_MIME_TYPE)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
