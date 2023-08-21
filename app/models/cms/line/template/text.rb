class Cms::Line::Template::Text < Cms::Line::Template::Base
  include Cms::Addon::Line::Template::Text

  field :text, type: String
  permit_params :text
  validates :text, presence: true, length: { maximum: 1200 }

  def type
    "text"
  end

  def balloon_html
    h = []
    h << '<div class="talk-balloon">'
    h << ApplicationController.helpers.br(text)
    h << '</div>'
    h.join
  end

  def body
    {
      type: "text",
      text: text.to_s
    }
  end

  def new_clone
    item = super
    item.text = text
    item
  end
end
