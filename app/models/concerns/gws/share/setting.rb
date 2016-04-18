module Gws::Share::Setting
  extend ActiveSupport::Concern
  extend Gws::Setting

  included do
    field :share_max_file_size, type: Integer, default: 0
    attr_accessor :in_share_max_file_size_mb

    permit_params :share_max_file_size, :in_share_max_file_size_mb

    before_validation :set_share_max_file_size

    validates :share_max_file_size, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  end

  class << self
    # Permission for navigation view
    def allowed?(action, user, opts = {})
      return true if Gws::Share::Category.allowed?(action, user, opts)
      #super
      false
    end
  end

  private
    def set_share_max_file_size
      return if in_share_max_file_size_mb.blank?
      self.share_max_file_size = Integer(in_share_max_file_size_mb) * 1_024 * 1_024
    end
end
