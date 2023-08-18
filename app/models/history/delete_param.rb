class History::DeleteParam
  include ActiveModel::Model
  include ActiveModel::Attributes

  attr_accessor :cur_site, :cur_user

  attribute :delete_term, :string

  validates :delete_term, inclusion: { in: %w(1.year 1.month), allow_blank: true }

  def delete_term_options
    %w(1.year 1.month).map do |v|
      [ I18n.t("ss.options.duration.#{v.sub(".", "_")}"), v ]
    end
  end

  def delete_term_in_time(now = nil)
    now ||= Time.zone.now
    return now if delete_term.blank?

    now - SS::Duration.parse(delete_term)
  end
end
