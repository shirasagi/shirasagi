class SS::Migration20210628000000
  include SS::Migration::Base

  depends_on "20210622000000"

  def change
    criteria = Cms::Page.all.unscoped
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |page|
        next unless page.site
        page.try(:new_size_input)
      end
    end
  end
end
