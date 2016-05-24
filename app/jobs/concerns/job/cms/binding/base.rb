module Job::Cms::Binding::Base
  extend ActiveSupport::Concern
  include Job::Cms::Binding::Site
  include Job::Cms::Binding::Group
  include Job::Cms::Binding::User
  include Job::Cms::Binding::Node
  include Job::Cms::Binding::Page
  include Job::Cms::Binding::Member

end
