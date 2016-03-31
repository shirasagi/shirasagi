module Gws::Board::Setting
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :board_new_days, type: Integer

    permit_params :board_new_days
  end

  def board_new_days
    self[:board_new_days].presence || 7
  end
end
