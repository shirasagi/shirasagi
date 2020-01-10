class SS::DownloadParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user
  attribute :encoding, :string

  validates :encoding, presence: true, inclusion: { in: %w(Shift_JIS UTF-8), allow_blank: true }
end
