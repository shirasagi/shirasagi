module Job::Cms::Binding::Group
  extend ActiveSupport::Concern
  include Job::SS::Binding::Group

  included do
    self.group_class = Cms::Group
  end
end
