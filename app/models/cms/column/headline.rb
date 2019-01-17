class Cms::Column::Headline < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  def headline_list
    {
      h1: "h1",
      h2: "h2",
      h3: "h3",
      h4: "h4"
    }
  end

  def form_options(type = nil)
    if type == :head
      options = {}
      options
    else
      super()
    end
  end

  def syntax_check_enabled?
    true
  end
end
