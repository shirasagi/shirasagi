module Fs::FilePreviewable
  extend ActiveSupport::Concern

  def file_previewable?(file, site:, user:, member:)
    false
  end
end
