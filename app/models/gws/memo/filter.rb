class Gws::Memo::Filter
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::SitePermission

  set_permission_name 'private_gws_memo_messages', :edit

  field :name, type: String
  field :subject, type: String
  field :body, type: String
  field :action, type: String
  field :state, type: String, default: 'enabled'
  field :order, type: Integer, default: 0

  embeds_ids :from_members, class_name: "Gws::User"
  embeds_ids :to_members, class_name: "Gws::User"

  belongs_to :folder, class_name: 'Gws::Memo::Folder'

  permit_params :name, :subject, :body, :action, :folder, :state, :order
  permit_params from_member_ids: [], to_member_ids: []

  validates :name, presence: true
  validates :action, presence: true
  validates :folder, presence: true, if: ->{ action != 'trash' }

  validate :validate_conditions

  default_scope -> { order_by order: 1 }

  scope :enabled, -> { where state: 'enabled' }

  scope :search, ->(params) {
    criteria = where({})
    return criteria if params.blank?

    criteria = criteria.keyword_in params[:keyword], :name if params[:keyword].present?
    criteria
  }

  private

  def validate_conditions
    if from_member_ids.blank? && to_member_ids.blank? && subject.blank? && body.blank?
      errors.add :base, I18n.t('gws/memo/filter.errors.blank_conditions')
    end
  end

  public

  def state_options
    %w(enabled disabled).map { |m| [I18n.t(m, scope: 'ss.options.state'), m] }
  end

  def action_options
    %w(move trash).map { |m| [I18n.t(m, scope: 'gws/memo/filter.options.action'), m] }
  end

  def folder_options(user)
    Gws::Memo::Folder.user(user).map do |folder|
      [ ERB::Util.html_escape(folder.name).html_safe, folder.id ]
    end
  end

  def state_name
    I18n.t(state, scope: 'ss.options.state')
  end

  def action_name
    I18n.t(action, scope: 'gws/memo/filter.options.action')
  end

  def match?(message)
    return true if subject_match?(message)
    return true if body_match?(message)
    return true if from_match?(message)
    return true if to_match?(message)
    false
  end

  def subject_match?(message)
    return false if subject.blank?
    message.display_subject.include?(subject)
  end

  def body_match?(message)
    return false if body.blank?
    if message.format == "html"
      message.html.to_s.include?(body)
    else
      message.text.to_s.include?(body)
    end
  end

  def from_match?(message)
    return false if from_member_ids.blank?
    from_member_ids.include?(message.user_id)
  end

  def to_match?(message)
    return false if to_member_ids.blank?
    (to_member_ids & (message.to_member_ids + message.cc_member_ids)).present?
  end

  def path
    (action == 'trash') ? 'INBOX.Trash' : folder.id.to_s
  end
end
