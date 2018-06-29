class Cms::Form
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Addon::LayoutHtml
  include Cms::Addon::GroupPermission
  include History::Addon::Backup

  set_permission_name 'cms_forms'

  seqid :id
  field :name, type: String
  field :order, type: Integer, default: 0
  field :state, type: String
  has_many :columns, class_name: 'Cms::Column::Base', dependent: :destroy, inverse_of: :form

  attr_accessor :cur_user

  permit_params :name, :order, :state

  validates :name, presence: true, length: { maximum: 80 }
  validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
  validates :state, presence: true, inclusion: { in: %w(public closed), allow_blank: true }

  scope :and_public, -> {
    where(state: 'public')
  }

  class << self
    def search(params = {})
      criteria = self.where({})
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

  def state_options
    %w(public closed).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def build_column_values(hash)
    hash = hash.to_unsafe_h if hash.respond_to?(:to_unsafe_h)
    hash.map do |key, value|
      column = columns.find(key) rescue nil
      next nil if column.blank?

      column.serialize_value(value)
    end
  end
end
