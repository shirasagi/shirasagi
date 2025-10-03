class SS::Migration20260403000000
  include SS::Migration::Base

  def change
    return if SS.config.cms.disable_redirect_link != false

    ids = Cms::Site.all.pluck(:id)
    ids.each do |id|
      site = Cms::Site.find(id) rescue nil
      next if site.nil?
      site.redirect_link_state = "enabled"
      site.update
    end
  end
end
