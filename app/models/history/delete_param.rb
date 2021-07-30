class History::DeleteParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user
  attribute :delete_term, :string

  validates :delete_term, presence: true, inclusion: { in: %w(year month all_delete), allow_blank: true }

  def delete_term_options
    %w(year month all_delete).map do |v|
      [ I18n.t("history.save_term.#{v}"), v ]
    end
  end

  def delete_term_in_time(now = nil)
    now ||= Time.zone.now

    case delete_term
    when "year"
      now - 1.year
    when "month"
      now - 1.month
    when "all_delete"
      now
    end
  end
end
