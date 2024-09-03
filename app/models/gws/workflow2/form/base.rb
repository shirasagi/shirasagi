class Gws::Workflow2::Form::Base
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Addon::Workflow2::FormCategory
  include Gws::Addon::Workflow2::FormPurpose
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission

  set_permission_name :gws_workflow2_forms

  readable_setting_include_custom_groups
  permission_include_custom_groups
  no_needs_read_permission_to_read

  field :name, type: String
  field :order, type: Integer
  field :state, type: String, default: 'closed'
  field :description, type: String
  field :memo, type: String

  permit_params :name, :order, :description, :memo

  validates :name, presence: true, length: { maximum: Gws.max_name_length }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }

  # # indexing to elasticsearch via companion object
  # around_save ::Gws::Elasticsearch::Indexer::Workflow2FormJob.callback
  # around_destroy ::Gws::Elasticsearch::Indexer::Workflow2FormJob.callback

  class << self
    SEARCH_HANDLERS = %i[search_keyword search_category search_category_criteria search_purpose].freeze

    def and_public
      all.where(state: 'public')
    end

    def search(params)
      return all if params.blank?

      criteria = all
      SEARCH_HANDLERS.each do |handler|
        criteria = criteria.send(handler, params)
      end
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?

      all.keyword_in(params[:keyword], :name, :description, method: params[:keyword_operator] || "and")
    end

    def search_category(params)
      if params[:category_id].present? && params[:category_id].numeric?
        all.where(category_ids: params[:category_id].to_i)
      elsif params[:category_ids].present?
        category_ids = params[:category_ids].select(&:numeric?).map(&:to_i)
        all.where("$and" => category_ids.map { |category_id| { category_ids: category_id } })
      else
        all
      end
    end

    def search_category_criteria(params)
      return all if params.blank? || params[:category_criteria].blank?

      all.where(params[:category_criteria])
    end

    def search_purpose(params)
      return all if params.blank? || params[:purpose_id].blank?
      all.where(purpose_ids: params[:purpose_id].to_i)
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
