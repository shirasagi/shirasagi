class Cms::Column::Youtube < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  def form_options(type = nil)
    if type == :url
      options = super()
      options['type'] = 'url'
      options
    else
      super()
    end
  end
end
