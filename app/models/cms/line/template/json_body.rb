class Cms::Line::Template::JsonBody < Cms::Line::Template::Base
  include Cms::Addon::Line::Template::JsonBody

  def type
    "json_body"
  end

  def balloon_html
    h = []
    h << '<div class="talk-balloon">'
    h << '<div style="font-weight: bold;">{JSONテンプレート;}</div>'
    h << '</div>'
    h.join
  end

  def new_clone
    item = super
    item.json_body = json_body
    item
  end
end
