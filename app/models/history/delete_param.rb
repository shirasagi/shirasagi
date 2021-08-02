class History::DeleteParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user
  attribute :delete_term, :string

  validates :delete_term, presence: true, inclusion: { in: %w(1.year 1.month all_delete), allow_blank: true }

  def delete_term_options
    options1 = %w(1.year 1.month).map do |v|
      [ I18n.t("ss.options.duration.#{v.sub(".", "_")}"), v ]
    end
    options2 = %w(all_delete).map do |v|
      [ I18n.t("history.options.duration.#{v}"), v ]
    end
    options1 + options2
  end

  def delete_term_in_time(now = nil)
    History.term_to_date(delete_term, now)
  end
end
