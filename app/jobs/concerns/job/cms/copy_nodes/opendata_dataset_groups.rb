module Job::Cms::CopyNodes::OpendataDatasetGroups
  extend ActiveSupport::Concern
  include SS::Copy::OpendataDatasetGroups
  include Job::Cms::CopyNodes::CmsContents
end
