module Job::Gws::Binding::Base
  extend ActiveSupport::Concern
  include Job::Gws::Binding::Site
  include Job::Gws::Binding::User
end
