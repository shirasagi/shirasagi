module Job::Cms::Binding::User
  extend ActiveSupport::Concern
  include Job::SS::Binding::User

  included do
    self.user_class = Cms::User
  end
end
