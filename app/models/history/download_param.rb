class History::DownloadParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user, :user_ids
  attribute :encoding, :string
  attribute :save_term, :string

  validates :encoding, presence: true, inclusion: { in: %w(Shift_JIS UTF-8), allow_blank: true }
  validates :save_term, presence: true, inclusion: { in: %w(1.day 1.month 1.year all_save), allow_blank: true }

  def save_term_options
    options1 = %w(1.day 1.month 1.year).map do |v|
      [ I18n.t("ss.options.duration.#{v.sub(".", "_")}"), v ]
    end
    options2 = %w(all_save).map do |v|
      [ I18n.t("history.options.duration.#{v}"), v ]
    end
    options1 + options2
  end

  def save_term_in_time(now = nil)
    History.term_to_date(save_term, now)
  end
end
