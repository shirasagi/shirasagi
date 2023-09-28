module History

  DOWNLOAD_MIME_TYPES = %w(text/csv application/zip).freeze

  mattr_accessor :max_histories
  self.max_histories = 10

end
