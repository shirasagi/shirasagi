module Fs::FilePreviewable
  extend ActiveSupport::Concern

  def file_previewable?(user, file)
    false
  end
end
