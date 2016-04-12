module Gws::Board::Setting
  extend ActiveSupport::Concern
  extend Gws::Setting

  included do
    field :board_new_days, type: Integer

    permit_params :board_new_days
  end

  def board_new_days
    self[:board_new_days].presence || 7
  end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Board::Category.allowed?(action, user, opts)
      super
    end
  end
end
