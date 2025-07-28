class Cms::Line::Statistic
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::Line::Statistic::Body
  include Cms::Addon::Line::Statistic::Info
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  MAX_OF_AGGREGATION_UNITS_BY_MONTH = 1000

  set_permission_name "cms_line_statistics", :use

  seqid :id
  field :name, type: String
  field :action, type: String
  field :condition_state, type: String
  field :condition_label, type: String
  field :request_id, type: String
  field :aggregation_unit, type: String
  field :statistics, type: Hash, default: {}
  field :member_count, type: Integer, default: 0
  field :aggregation_units_by_month, type: Integer

  belongs_to :message, class_name: "Cms::Line::Message", inverse_of: :statistics

  validates :name, presence: true, length: { maximum: 80 }
  validates :action, inclusion: { in: %w(broadcast multicast) }
  validates :aggregation_unit, presence: true, if: -> { multicast? }

  before_validation :set_aggregation_unit, if: -> { multicast? }

  default_scope -> { order_by(created: -1) }

  def broadcast?
    action == "broadcast"
  end

  def multicast?
    action == "multicast"
  end

  def set_aggregation_unit
    self.aggregation_unit ||= self.class.ss_short_uuid
  end

  def exceeded_units_by_month?
    return false if broadcast?
    return false if aggregation_units_by_month.nil?
    aggregation_units_by_month >= MAX_OF_AGGREGATION_UNITS_BY_MONTH
  end

  def update_statistics
    broadcast? ? update_broadcast_statistics : update_multicast_statistics
  end

  # ref: https://developers.line.biz/ja/reference/messaging-api/#get-message-event
  def update_broadcast_statistics
    res = site.line_client.get_user_interaction_statistics(request_id)
    raise "#{res.code} #{res.body}" if res.code !~ /^2\d\d$/
    self.statistics = JSON.parse(res.body)
    update!
  rescue => e
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    false
  end

  # ref: https://developers.line.biz/ja/reference/messaging-api/#get-statistics-per-unit
  def update_multicast_statistics
    from = created.strftime("%Y%m%d")
    to = created.advance(days: 14).strftime("%Y%m%d")
    res = site.line_client.get_statistics_per_unit(unit: aggregation_unit, from: from, to: to)
    raise "#{res.code} #{res.body}" if res.code !~ /^2\d\d$/
    self.statistics = JSON.parse(res.body)
    update!
  rescue => e
    Rails.logger.error("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
    false
  end

  def root_owned?(user)
    true
  end

  def condition_state_options
    I18n.t("cms.options.line_deliver_condition_state").map { |k, v| [v, k] }
  end

  class << self
    def ss_short_uuid
      "ss_#{ShortUUID.shorten(SecureRandom.uuid)}"
    end

    def create_from_message(message)
      item = self.new
      item.cur_site = message.site
      item.cur_user = message.user
      item.message = message
      item.name = message.name
      item.action = message.deliver_action
      item.condition_state = message.deliver_condition_state
      item.condition_label = message.deliver_condition_label
      item.group_ids = message.group_ids

      if item.multicast?
        # メッセージ送信時の numOfCustomAggregationUnits を保存する
        item.aggregation_units_by_month = get_aggregation_units_by_month(message.site)
      end

      item.save!
      item
    end

    def get_aggregation_units_by_month(site)
      res = site.line_client.get_aggregation_info
      (JSON.parse(res.body))['numOfCustomAggregationUnits'].to_i
    end

    def enum_csv(options = {})
      criteria = all
      drawer = SS::Csv.draw(:export, context: self) do |drawer|
        drawer.column :message_id do
          drawer.body { |item| item.name }
        end
        drawer.column :condition_state do
          drawer.body { |item| item.label(:condition_state) }
        end
        drawer.column :condition_label
        drawer.column :overview_delivered
        drawer.column :overview_unique_impression
        drawer.column :overview_openrate
        drawer.column :created
        drawer.column :updated
      end
      drawer.enum(criteria, options)
    end

    def search(params)
      criteria = all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name
      end
      criteria
    end
  end
end
