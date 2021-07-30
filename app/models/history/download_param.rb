class History::DownloadParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user, :user_ids
  attribute :encoding, :string
  attribute :save_term, :string

  validates :encoding, presence: true, inclusion: { in: %w(Shift_JIS UTF-8), allow_blank: true }
  validates :save_term, presence: true, inclusion: { in: %w(day month year all_save), allow_blank: true }

  def save_term_options
    %w(day month year all_save).map do |v|
      [ I18n.t("history.save_term.#{v}"), v ]
    end
  end

  def save_term_in_time(now = nil)
    now ||= Time.zone.now

    case save_term
    when "year"
      now - 1.year
    when "month"
      now - 1.month
    when "day"
      now - 1.day
    when "all_save"
      nil
    else
      false
    end
  end
end
