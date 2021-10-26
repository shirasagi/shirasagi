class SS::Migration20150521192401
  include SS::Migration::Base

  depends_on "20150518040533"

  def change
    criteria = Cms::Page.all
    all_ids = criteria.pluck(:id)
    all_ids.each_slice(20) do |ids|
      criteria.in(id: ids).to_a.each do |page|
        next unless page.site

        if page.respond_to?(:files)
          page.files.exists(site_id: false).each do |file|
            file.set(site_id: page.site.id)
          end
        end

        if page.route == 'ads/banner' && page.file.present? && page.file.site_id.blank?
          page.file.set(site_id: page.site.id)
        end

        if page.route == 'facility/image' && page.image.present? && page.image.site_id.blank?
          page.image.set(site_id: page.site.id)
        end
      end
    end
  end
end
