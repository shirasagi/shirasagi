module Job::Gws::Binding::User
  extend ActiveSupport::Concern
  include Job::SS::Binding::User

  included do
    self.user_class = Gws::User
  end
end
