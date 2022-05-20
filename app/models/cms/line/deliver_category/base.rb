class Cms::Line::DeliverCategory::Base
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include Cms::SitePermission

  store_in collection: "cms_line_deliver_categories"

  set_permission_name "cms_line_deliver_categories", :use

  seqid :id
  field :name
  field :type, type: String
  field :order, type: Integer, default: 0
  field :depth, type: Integer
  field :state, type: String, default: 'public'

  belongs_to :parent, class_name: "Cms::Line::DeliverCategory::Base", inverse_of: :children
  has_many :children, class_name: "Cms::Line::DeliverCategory::Base", dependent: :destroy, inverse_of: :parent,
    order: { order: 1 }

  permit_params :name, :type, :order, :state

  before_validation :set_type
  before_validation :set_depth

  validates :name, presence: true
  validates :depth, presence: true

  default_scope -> { order_by(order: 1) }

  def type_options
    self.class.type_options
  end

  def state_options
    %w(public closed).map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }
  end

  private

  def set_type
    self.type = self.class.inherit_types[self.class]
  end

  def set_depth
    self.depth = parent ? (parent.depth + 1) : 1
  end

  class << self
    def inherit_types
      [
        [Cms::Line::DeliverCategory::Category, "category"],
        [Cms::Line::DeliverCategory::ChildAge, "child_age"]
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
