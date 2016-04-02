module Job::SS::Reference::Base
  extend ActiveSupport::Concern
  include Job::SS::Reference::Site
  include Job::SS::Reference::Group
  include Job::SS::Reference::User

end
