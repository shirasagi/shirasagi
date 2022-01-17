class Cms::Column::TextArea < Cms::Column::Base
  include Cms::Addon::Column::TextLike

  def syntax_check_enabled?
    true
  end

  def link_check_enabled?
    true
  end

  def db_form_type
    { type: 'textarea', rows: 8 }
  end
end
