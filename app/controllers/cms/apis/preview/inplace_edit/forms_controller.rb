class Cms::Apis::Preview::InplaceEdit::FormsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Form

  layout "ss/ajax_in_iframe"

  before_action :set_inplace_mode
  before_action :set_item, only: :palette

  private

  def set_inplace_mode
    @inplace_mode = true
  end

  public

  def palette
    raise "404" unless @item.sub_type_entry?
  end
end
