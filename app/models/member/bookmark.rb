class Member::Bookmark
  include SS::Document
  include SS::Reference::Site
  include Cms::Reference::Member
  include SS::TemplateVariable
  include SS::Liquidization

  field :name, type: String
  belongs_to :content, class_name: "Object", polymorphic: true

  validates :name, presence: true

  before_validation :set_name

  default_scope ->{ order_by(updated: -1) }

  template_variable_handler(:name, :template_variable_handler_name)
  template_variable_handler(:index_name, :template_variable_handler_index_name)
  template_variable_handler(:class, :template_variable_handler_class)
  template_variable_handler(:url, :template_variable_handler_url)
  template_variable_handler(:cancel_link, :template_variable_handler_cancel_link)

  liquidize do
    export :name do
      content.try(:name)
    end
    export :index_name do
      content.try(:index_name).presence || content.try(:name)
    end
    export :css_class do
      "bookmark"
    end
    export :url do
      content.try(:url)
    end
    export :content do
      content
    end
    export as: :cancel_link do |context|
      cur_path = context.registers[:cur_path]
      node = context.registers[:cur_node]
      cancel_link(node, cur_path)
    end
  end

  def cancel_link(node, ref)
    url = node.url + "cancel?" + { path: content.url, ref: ref }.to_query
    ApplicationController.helpers.link_to(I18n.t("member.links.cancel_bookmark"), url, { method: :post, class: "favorite-cancel" })
  end

  def becomes_with_route
    self
  end

  private

  def set_name
    self.name = content.try(:name)
  end

  def template_variable_handler_name(*_)
    content.try(:name)
  end

  def template_variable_handler_index_name(*_)
    content.try(:name)
  end

  def template_variable_handler_url(*_)
    content.try(:url)
  end

  def template_variable_handler_cancel_link(*_)
    false
  end

  def template_variable_handler_class(*_)
    "bookmark"
  end

  class << self
    def and_public
      where(:deleted.exists => false)
    end

    def and_pages
      where(content_type: /::Page$/)
    end
  end
end
