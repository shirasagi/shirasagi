class Ads::AccessLog
  include SS::Document
  include SS::Reference::Site

  store_in_repl_master
  #index({ site_id: 1, node_id: 1, date: -1 })

  field :node_id, type: Integer
  field :link_url, type: String
  field :date, type: Date
  field :count, type: Integer, default: 0

  validates :site_id, presence: true
  validates :node_id, presence: true
  validates :link_url, presence: true
  validates :date, presence: true

  class << self
    def to_csv
      I18n.with_locale(I18n.default_locale) do
        CSV.generate do |data|
          data << %w(date link_url count).map { |k| t(k) }
          criteria.each do |item|
            line = []
            line << I18n.l(item.date.to_date, format: :picker)
            line << item.link_url
            line << item.count
            data << line
          end
        end
      end
    end
  end
end
