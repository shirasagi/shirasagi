module Job::Cms::CopyNodes::CmsForms
  extend ActiveSupport::Concern
  include SS::Copy::CmsForms
  include Job::Cms::CopyNodes::CmsContents
end
