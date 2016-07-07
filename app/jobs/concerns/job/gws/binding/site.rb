module Job::Gws::Binding::Site
  extend ActiveSupport::Concern
  include Job::SS::Binding::Site

  included do
    self.site_class = Gws::Group
  end
end
