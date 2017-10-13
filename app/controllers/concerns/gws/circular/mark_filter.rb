module Gws::Circular::MarkFilter
  extend ActiveSupport::Concern

  included do
    before_action :set_item, only: [
        :show, :edit, :update, :delete, :destroy,
        :mark, :unmark
    ]

    model Gws::Circular::Topic
  end

  def mark
    raise '403' unless @item.markable?(@cur_user)
    render_update @item.marked_by(@cur_user).update
  end

  def unmark
    raise '403' unless @item.unmarkable?(@cur_user)
    render_update @item.unmarked_by(@cur_user).update
  end

end
