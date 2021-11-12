class History::DownloadParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user, :user_ids

  attribute :encoding, :string
  attribute :save_term, :string

  validates :encoding, presence: true, inclusion: { in: %w(Shift_JIS UTF-8), allow_blank: true }
  validates :save_term, inclusion: { in: %w(1.day 1.month 1.year), allow_blank: true }

  def save_term_options
    %w(1.day 1.month 1.year).map do |v|
      [ I18n.t("ss.options.duration.#{v.sub(".", "_")}"), v ]
    end
  end

  def save_term_in_time(now = nil)
    return if save_term.blank?

    now ||= Time.zone.now
    now - SS::Duration.parse(save_term)
  end
end
