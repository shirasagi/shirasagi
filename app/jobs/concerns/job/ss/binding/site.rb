module Job::SS::Binding::Site
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

  def bind(bindings)
    if bindings['site_id'].present?
      self.site_id = bindings['site_id'].to_param
      @site = nil
    end
    super
  end

  def bindings
    ret = super
    ret.merge!({ 'site_id' => site_id }) if site_id.present?
    ret
  end
end
