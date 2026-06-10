class Gws::Tabular::File::DownloadParam < SS::DownloadParam
  attribute :format, :string, default: "csv"

  validates :format, inclusion: { in: %w(csv zip), allow_blank: true }
end
