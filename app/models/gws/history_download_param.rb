class Gws::HistoryDownloadParam < SS::DownloadParam
  attribute :from, :datetime
  attribute :to, :datetime

  validates :from, presence: true
  validates :to, presence: true
end
