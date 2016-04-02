module Job::Cms::Reference::Site
  extend ActiveSupport::Concern
  include Job::SS::Reference::Site

  included do
    self.site_class = Cms::Site
  end
end
