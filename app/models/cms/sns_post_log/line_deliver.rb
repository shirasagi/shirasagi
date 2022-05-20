class Cms::SnsPostLog::LineDeliver < Cms::SnsPostLog::Line
  field :deliver_name, type: String
  field :deliver_mode, type: String, default: "main"

  attr_accessor :in_members
  embeds_ids :members, class_name: 'Cms::Member'
  embeds_ids :test_members, class_name: 'Cms::Line::TestMember'

  before_validation :set_in_members

  def deliver_mode_options
    I18n.t("cms.options.deliver_mode").map { |k, v| [v, k] }
  end

  def extract_deliver_members
    (deliver_mode == "main") ? members : test_members
  end

  def root_owned?(user)
    true
  end

  private

  def set_in_members
    if deliver_mode == "main"
      self.member_ids = in_members.map(&:id)
    elsif deliver_mode == "test"
      self.test_member_ids = in_members.map(&:id)
    end
  end

  def set_name
    super
    self.deliver_name ||= "[#{label(:deliver_mode)}] #{source.try(:name)}"
  end

  class << self
    def create_with(item)
      log = self.new
      log.site = item.site
      log.source_name = item.name
      log.source = item
      yield(log)
      log.save
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :deliver_name
      end
      criteria
    end
  end
end
