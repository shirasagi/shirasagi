class SS::Migration20191205000000
  include SS::Migration::Base

  depends_on "20181214000000"

  def change
    each_opendata_site do |site|
      modified = false

      if site.anti_bot_methods.blank?
        site.anti_bot_methods = %w(set_nofollow)
        modified = true
      end

      if modified
        site.save
      end
    end
  end

  private

  def each_opendata_site(&block)
    all_site_ids = Opendata::Dataset.all.pluck(:site_id).uniq
    return if all_site_ids.blank?

    all_site_ids.each_slice(20) do |site_ids|
      sites = Cms::Site.all.in(id: site_ids).to_a
      sites.each(&block)
    end
  end
end
