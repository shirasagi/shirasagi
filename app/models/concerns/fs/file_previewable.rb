module Fs::FilePreviewable
  extend ActiveSupport::Concern

  def file_previewable?(file, user:, member:)
    false
  end
end
