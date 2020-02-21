module Job::Cms::CopyNodes::CmsColumns
  extend ActiveSupport::Concern
  include SS::Copy::CmsColumns
  include Job::Cms::CopyNodes::CmsContents
end
