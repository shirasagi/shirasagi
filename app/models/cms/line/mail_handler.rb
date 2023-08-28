class Cms::Line::MailHandler
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::Addon::Line::Message::DeliverCondition
  include Cms::SitePermission
  include Cms::Addon::GroupPermission
  #include History::Addon::Backup

  set_permission_name "cms_line_mail_handlers", :use

  seqid :id
  field :name, type: String
  field :filename, type: String
  field :from_conditions, type: SS::Extensions::Lines
  field :to_conditions, type: SS::Extensions::Lines
  field :terminate_line, type: String
  field :order, type: Integer, default: 0
  field :handle_state, type: String, default: "deliver"
  field :statistic_state, type: String, default: "disabled"

  permit_params :name, :filename, :from_conditions, :to_conditions,
    :terminate_line, :order, :handle_state, :statistic_state

  validates :name, presence: true, length: { maximum: 40 }
  validates :filename, presence: true, uniqueness: { scope: :site_id }, length: { maximum: 200 }
  validate :validate_filename

  def order
    value = self[:order].to_i
    value < 0 ? 0 : value
  end

  def handle_state_options
    I18n.t("cms.options.handle_state").map { |k, v| [v, k] }
  end

  def statistic_state_options
    %w(disabled enabled).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
  end

  def enabled?
    handle_state == "deliver" || handle_state = "draft"
  end

  def disabled?
    !enabled?
  end

  def handle_message(data)
    SS::MailHandler.write_eml(data, "cms_line")
    mail = ::Mail.new(data)

    from = mail.from[0]
    from_domain = from.sub(/^.+@/, "")
    to = mail.to[0]
    to_domain = to.sub(/^.+@/, "")

    body = mail.text_part ? mail.text_part.decoded : mail.decoded
    body = body.gsub(/\r\n/, "\n").squeeze("\n").strip
    body = body.sub(/#{terminate_line}.+$/m, "").strip if terminate_line.present?
    subject = mail.subject

    # check from, to
    if disabled?
      raise "mail handler is disabled"
    end
    if (from_conditions.to_a & [from, from_domain]).blank?
      raise "from conditions unmatched"
    end
    if (to_conditions.to_a & [to, to_domain]).blank?
      raise "to conditions unmatched"
    end

    # create message
    item = Cms::Line::Message.new
    item.cur_site = site
    item.cur_user = user
    item.group_ids = group_ids
    item.name = "[#{name}] #{subject}"
    item.statistic_state = statistic_state

    item.deliver_condition_state = deliver_condition_state
    item.deliver_condition_id = deliver_condition_id
    item.deliver_category_ids = deliver_category_ids
    item.save!

    template = Cms::Line::Template::Text.new
    template.text = body
    template.cur_site = site
    template.cur_user = user
    template.message = item
    template.save!

    # execute job
    if handle_state == "deliver" && !item.deliver
      raise "message deliver faild"
    end

    item
  end

  private

  def validate_filename
    return if filename.blank?
    errors.add :filename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+$/
  end

  class << self
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

    def and_enabled
      self.in(handle_state: %w(deliver draft))
    end
  end
end
