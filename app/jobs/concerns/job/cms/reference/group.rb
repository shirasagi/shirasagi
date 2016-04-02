module Job::Cms::Reference::Group
  extend ActiveSupport::Concern
  include Job::SS::Reference::Group

  included do
    self.group_class = Cms::Group
  end
end
