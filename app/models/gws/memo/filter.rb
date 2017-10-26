class Gws::Memo::Filter
  include SS::Document
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::GroupPermission

  set_permission_name 'gws_memo_messages'

  # 一括処理件数
  APPLY_PER = 100

  field :name, type: String
  field :from, type: String
  field :subject, type: String
  field :action, type: String
  field :state, type: String, default: 'enabled'
  field :order, type: Integer, default: 0

  belongs_to :folder, class_name: 'Gws::Memo::Folder'

  permit_params :name, :from, :subject, :action, :folder, :state, :order

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

  def state_options
    %w(enabled disabled).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def action_options
    %w(move trash).map { |m| [I18n.t("gws/memo/filter.options.action.#{m}"), m] }
  end

  def folder_options(user, site)
    Gws::Memo::Folder.site(site).allow(:read, user, site: site).map do |folder|
      [ERB::Util.html_escape(folder.name).html_safe, folder.id]
    end
  end

  def state_name
    I18n.t(state, scope: 'ss.options.state')
  end

  def action_name
    I18n.t(action, scope: 'gws/memo/filter.options.action')
  end

  private

  def validate_conditions
    %w(from subject).each do |key|
      return true if send(key).present?
    end
    errors.add :base, I18n.t('gws/memo/filter.errors.blank_conditions')
  end
end
