module Job::Cms::Binding::Site
  extend ActiveSupport::Concern
  include Job::SS::Binding::Site

  included do
    self.site_class = Cms::Site
  end
end
