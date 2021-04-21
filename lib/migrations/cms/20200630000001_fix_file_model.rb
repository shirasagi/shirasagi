class SS::Migration20200630000001
  include SS::Migration::Base

  depends_on "20200630000000"

  def change
    each_file do |file|
      file.set(model: file.owner_item_type.underscore)
    end
  end

  private

  def each_file(&block)
    criteria = SS::File.where(model: "inquiry/answer").exists(owner_item_type: true)
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each(&block)
    end
  end
end
