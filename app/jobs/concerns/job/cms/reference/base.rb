module Job::Cms::Reference::Base
  extend ActiveSupport::Concern
  include Job::Cms::Reference::Site
  include Job::Cms::Reference::Group
  include Job::Cms::Reference::User
  include Job::Cms::Reference::Node
  include Job::Cms::Reference::Page
  include Job::Cms::Reference::Member

end
