class Gws::Workflow::Form
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Workflow::ColumnSetting
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  readable_setting_include_custom_groups
  permission_include_custom_groups

  field :name, type: String
  field :order, type: Integer
  field :state, type: String, default: 'closed'
  field :memo, type: String

  permit_params :name, :order, :memo

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }

  scope :and_public, ->{
    where(state: 'public')
  }

  class << self
    def search(params)
      criteria = all
      return criteria if params.blank?

      criteria = criteria.search_keyword(params)
      criteria
    end

    def search_keyword(params)
      return all if params[:keyword].blank?

      all.keyword_in(params[:keyword], :name)
    end
  end

  def state_options
    %w(closed public).map { |m| [I18n.t("ss.options.state.#{m}"), m] }
  end

  def closed?
    !public?
  end

  def public?
    state == 'public'
  end
end
