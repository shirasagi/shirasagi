module Job::Gws::Binding::Group
  extend ActiveSupport::Concern
  include Job::SS::Binding::Group

  included do
    self.group_class = Gws::Group
  end
end
