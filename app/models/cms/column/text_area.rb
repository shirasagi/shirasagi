class Cms::Column::TextArea < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  def syntax_check_enabled?
    true
  end
end
