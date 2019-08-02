module Job::Cms::CopyNodes::OpendataLicenses
  extend ActiveSupport::Concern
  include SS::Copy::OpendataLicenses
  include Job::Cms::CopyNodes::CmsContents
end
