module Job::Cms::Reference::User
  extend ActiveSupport::Concern
  include Job::SS::Reference::User

  included do
    self.user_class = Cms::User
  end
end
