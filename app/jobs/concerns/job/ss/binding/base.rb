module Job::SS::Binding::Base
  extend ActiveSupport::Concern
  include Job::SS::Binding::Site
  include Job::SS::Binding::Group
  include Job::SS::Binding::User

end
