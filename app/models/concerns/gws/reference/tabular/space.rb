module Gws::Reference::Tabular::Space
  extend ActiveSupport::Concern
  extend SS::Translation

  attr_writer :cur_space

  included do
    belongs_to :space, class_name: 'Gws::Tabular::Space'

    before_validation :set_space_id, if: ->{ @cur_space }

    scope :space, ->(space) { where(space_id: space.id) }
  end

  def cur_space
    @cur_space ||= self.space
  end

  private

  def set_space_id
    return unless @cur_space
    self.space_id = @cur_space.id
  end
end
