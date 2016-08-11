module Job::Cms::CopyNodes::SsFiles
  extend ActiveSupport::Concern

  def resolve_file_reference(id)
    id
  end
end
