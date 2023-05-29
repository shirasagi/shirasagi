class Guidance::Result
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include SS::Reference::User
  include Cms::Reference::Node
  include Cms::Addon::GroupPermission
  include History::Addon::Backup
  include Guidance::ConditionFields
  include Guidance::ResultImport

  set_permission_name "guidance_results"

  seqid :id
  field :name, type: String
  field :order, type: Integer
  field :text, type: String

  permit_params :name, :order, :text

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }

  default_scope -> { order_by(order: 1, name: 1) }

  class << self
    def search(params = {})
      criteria = self.all
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :text
      end
      criteria
    end

    def to_hash_list
      criteria.map do |item|
        {
          id: item.id,
          name: item.name,
          text: item.text,
          condition_and: item.complement_condition_and.to_a,
          condition_or1: item.complement_condition_or1.to_a,
          condition_or2: item.complement_condition_or2.to_a,
          condition_or3: item.complement_condition_or3.to_a,
        }
      end
    end
  end
end
