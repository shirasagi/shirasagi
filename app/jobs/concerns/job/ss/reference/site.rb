module Job::SS::Reference::Site
  extend ActiveSupport::Concern

  included do
    # site class
    mattr_accessor(:site_class, instance_accessor: false) { SS::Site }
    # site
    attr_accessor :site_id
  end

  def site
    return nil if site_id.blank?
    @site ||= self.class.site_class.find(site_id) rescue nil
  end
end
