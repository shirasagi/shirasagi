class Gws::Tabular::DownloadParam < SS::DownloadParam
  attribute :format, :string

  validates :format, inclusion: { in: %w(csv zip), allow_blank: true }
end
