module SS::Model::ImageResize
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document

  STATE_ENABLED = 'enabled'.freeze
  STATE_DISABLED = 'disabled'.freeze
  STATES = [ STATE_ENABLED, STATE_DISABLED ].freeze

  included do
    attr_accessor :in_size_mb

    field :state, type: String
    field :max_width, type: Integer
    field :max_height, type: Integer
    field :size, type: Integer
    field :quality, type: Integer

    permit_params :max_width, :max_height, :size, :quality, :state
    permit_params :in_size_mb

    before_validation :set_size, if: ->{ in_size_mb }

    validates :state, inclusion: { in: STATES, allow_blank: true }
    validates :max_width, presence: true, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
    validates :max_height, presence: true, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
    validates :size, numericality: { only_integer: true, greater_than: 0, allow_blank: true }
    validates :quality, numericality: {
      only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_blank: true
    }
  end

  module ClassMethods
    def intersection(lhs, rhs)
      return rhs.dup if lhs.nil?
      return lhs.dup if rhs.nil?

      intersected_attr = {}
      %w(max_width max_height size quality).each do |attr|
        lhs_value = lhs.attributes[attr]
        rhs_value = rhs.attributes[attr]
        if lhs_value.nil?
          intersected_attr[attr] = rhs_value
        elsif rhs_value.nil?
          intersected_attr[attr] = lhs_value
        else
          diff = lhs_value <=> rhs_value
          if diff <= 0
            intersected_attr[attr] = lhs_value
          else
            intersected_attr[attr] = rhs_value
          end
        end
      end

      new(intersected_attr)
    end
  end

  def state_options
    STATES.map { |v| [ I18n.t("ss.options.state.#{v}"), v ] }.to_a
  end

  private

  def set_size
    if in_size_mb.numeric?
      self.size = in_size_mb.to_i * 1_024 * 1_024
    else
      self.size = nil
    end
  end
end
