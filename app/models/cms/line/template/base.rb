class Cms::Line::Template::Base
  include SS::Document
  include SS::Reference::User
  include SS::Reference::Site
  include SS::Relation::File
  include Fs::FilePreviewable

  belongs_to :message, class_name: "Cms::Line::Message"
  field :name, type: String
  field :order, type: Integer, default: 0

  permit_params :name, :order

  before_save :set_name

  default_scope -> { order_by(order: 1) }

  # Cms::Line::Template::Image relations (mongoid destroy not working if define relations in child class)
  belongs_to_file :image

  # Cms::Line::Template::Page relations
  belongs_to :page, class_name: "Cms::Page"
  permit_params :page_id

  def type
  end

  def type_options
    I18n.t("cms.options.line_template_type").map { |k, v| [v, k] }
  end

  def body
  end

  def json
    body.to_json
  end

  def balloon_html
  end

  def state
    message.state
  end

  def file_previewable?(file, site:, user:, member:)
    state == "public"
  end

  def allowed?(action, user, opts = {})
    return false unless message
    message.allowed?(action, user, opts)
  end

  def new_clone
    item = self.class.new
    item.site = site
    item.user = user
    item.order = order
    item
  end

  def owned_files
    files = SS::File.where(owner_item_type: self.class.name, owner_item_id: id).to_a
    if page
      _page = page.becomes_with_route
      files += SS::File.where(owner_item_type: _page.class.name, owner_item_id: _page.id).to_a
    end
    files
  end

  private

  def set_name
    self.name = message.try(:name)
  end

  class << self
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
  end
end
