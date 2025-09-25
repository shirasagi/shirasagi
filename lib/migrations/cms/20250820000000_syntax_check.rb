class SS::Migration20250820000000
  include SS::Migration::Base

  depends_on "20250801000000"

  def change
    sites = Cms::Site.all.to_a
    sites.each do |site|
      Cms::SyntaxCheckJob.bind(site_id: site.id).perform_now
    end
  end
end
