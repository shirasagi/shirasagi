class Cms::Line::DeliverCategory::Base
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission

  store_in collection: "cms_line_deliver_categories"

  set_permission_name "cms_line_deliver_categories", :use

  attr_accessor :basename

  seqid :id
  field :name
  field :filename
  field :order, type: Integer, default: 0
  field :remarks, type: String
  field :depth, type: Integer
  field :state, type: String, default: 'public'

  belongs_to :parent, class_name: "Cms::Line::DeliverCategory::Base", inverse_of: :children
  has_many :children, class_name: "Cms::Line::DeliverCategory::Base", dependent: :destroy, inverse_of: :parent,
    order: { order: 1 }

  permit_params :name, :filename, :basename, :type, :order, :state, :remarks

  before_validation :set_depth
  before_validation :set_filename
  before_validation :validate_filename
  validates :name, presence: true
  validates :filename, uniqueness: { scope: :site_id }, length: { maximum: 200 }
  validates :depth, presence: true
  after_save :rename_children, if: ->{ @db_changes }

  default_scope -> { order_by(order: 1) }

  def type
  end

  def type_options
    self.class.type_options
  end

  def state_options
    %w(public closed).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
  end

  def basename
    @basename.presence || filename.to_s.sub(/.*\//, "").presence
  end

  def effective_with?(other_ids)
    true
  end

  private

  def validate_filename
    if @basename
      return errors.add :basename, :empty if @basename.blank?
      errors.add :basename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+$/
      errors.add :basename, :invalid if @basename !~ /^([\w\-]+\/)*[\w\-]+$/
    else
      return errors.add :filename, :empty if filename.blank?
      errors.add :filename, :invalid if filename !~ /^([\w\-]+\/)*[\w\-]+$/
    end
  end

  def set_filename
    if parent
      self.filename = "#{parent.filename}/#{basename}"
    elsif @basename
      self.filename = basename
    end
  end

  def set_depth
    self.depth = parent ? (parent.depth + 1) : 1
  end

  def rename_children
    return unless @db_changes["filename"]
    return unless @db_changes["filename"][0]
    children.each(&:save)
  end

  class << self
    def inherit_types
      [
        [Cms::Line::DeliverCategory::Category, "category"],
        [Cms::Line::DeliverCategory::Selection, "selection"]
      ].to_h
    end

    def type_options
      inherit_types.map { |_, v| [I18n.t("cms.options.line_deliver_category_type.#{v}"), v] }
    end

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

    def and_public
      self.where(state: "public")
    end

    def and_closed
      self.where(state: "closed")
    end

    def and_root
      self.where(depth: 1)
    end

    def each_public
      self.and_root.and_public.each do |root|
        children = root.children.and_public.to_a
        yield(root, children)
      end
    end

    def page_condition
    end
  end
end
