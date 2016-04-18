module SS::Model::Group
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Scope::ActivationDate
  include Ldap::Addon::Group
  include SS::Fields::DependantNaming

  attr_accessor :in_password

  included do
    store_in collection: "ss_groups"
    index({ name: 1 }, { unique: true })

    seqid :id
    field :name, type: String
    field :order, type: Integer
    field :activation_date, type: DateTime
    field :expiration_date, type: DateTime
    permit_params :name, :order, :activation_date, :expiration_date

    default_scope -> { order_by(order: 1, name: 1) }

    validates :name, presence: true, uniqueness: true, length: { maximum: 80 }
    validates :activation_date, datetime: true
    validates :expiration_date, datetime: true
    validate :validate_name

    scope :in_group, ->(group) {
      where(name: /^#{group.name}(\/|$)/)
    }
  end

  module ClassMethods
    def search(params)
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

  def full_name
    name.tr("/", " ")
  end

  def section_name
    return name unless name.include?('/')
    name.split("/")[1..-1].join(' ')
  end

  def trailing_name
    name.split("/").pop
  end

  def root
    parts = name.try(:split, "/") || []
    return self if parts.length <= 1

    0.upto(parts.length - 1) do |c|
      ret = self.class.where(name: parts[0..c].join("/")).first
      return ret if ret.present?
    end
    nil
  end

  def root?
    id == root.id
  end

  def descendants
    self.class.where(name: /^#{name}\//)
  end

  # Soft delete
  def disable
    super
    descendants.each { |item| item.disable }
  end

  private
    def validate_name
      if name =~ /\/$/ || name =~ /^\// || name =~ /\/\//
        errors.add :name, :invalid
      end
    end
end
