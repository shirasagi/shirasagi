class SS::Migration20150807090501
  include SS::Migration::Base

  depends_on "20150619114301"

  def change
    criteria = Cms::Page.where(state: 'closed')
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |page|
        if page.respond_to?(:files)
          page.files.where(state: 'public').each do |f|
            f.update(state: page.state)
          end
        end

        if page.route == 'facility/image' && page.image.try(:state) == "public"
          page.image.update(state: page.state)
        end
      end
    end
  end
end
