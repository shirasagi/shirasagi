module Gws::Circular::MarkFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_item, only: [
        :show, :edit, :update, :delete, :destroy,
        :mark, :unmark, :toggle
    ]

    model Gws::Circular::Topic
  end

  def mark
    raise '403' unless @item.markable?(@cur_user)
    render_update @item.mark_by(@cur_user).update
  end

  def unmark
    raise '403' unless @item.unmarkable?(@cur_user)
    render_update @item.unmark_by(@cur_user).update
  end

  def toggle
    raise '403' unless @item.member?(@cur_user)
    render_update @item.toggle_by(@cur_user).update
  end
end
