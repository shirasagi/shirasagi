module SS::Model::CustomGroup
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Fields::DependantNaming

  attr_accessor :in_password

  included do
    store_in collection: "gws_custom_groups"
    index({ name: 1 })

    seqid :id
    field :name, type: String
    field :order, type: Integer
    permit_params :name, :order

    default_scope -> { order_by(order: 1, name: 1) }
    validates :name, presence: true, uniqueness: { scope: :site_id }, length: { maximum: 80 }
    validates :order, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 999_999, allow_blank: true }
    validate :validate_name

    scope :in_group, ->(group) {
      where(name: /^#{::Regexp.escape(group.name)}(\/|$)/)
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

    def tree_sort(options = {})
      SS::TreeList.build self, options
    end

    def roots
      self.not(name: /\//)
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
    @trailing_name ||= name.split("/")[depth..-1].join("/")
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
    self.class.where(name: /^#{::Regexp.escape(name)}\//)
  end

  def descendants_and_self
    self.class.in_group(self)
  end

  def parents
    return self.class.none unless name.include?("/")

    n = nil
    parent_names = name.sub("/#{trailing_name}", "").split(/\//)
    parent_names = parent_names.map { |name| n = (n ? "#{n}/#{name}" : name) }
    self.class.in(name: parent_names)
  end

  # Soft delete
  def disable
    super
    descendants.each { |item| item.disable }
  end

  def depth
    @depth ||= begin
      count = 0
      full_name = ""
      name.split('/').map do |part|
        full_name << "/" if full_name.present?
        full_name << part

        break if name == full_name

        found = self.class.where(name: full_name).first
        break if found.blank?

        count += 1
      end
      count
    end
  end

  def gws_use_options
    %w(disabled enabled).map { |v| [ I18n.t("ss.options.gws_use.#{v}"), v ] }
  end

  private

  def validate_name
    if name =~ /\/$/ || name =~ /^\// || name =~ /\/\//
      errors.add :name, :invalid
    end
  end
end
