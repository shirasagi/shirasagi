module Lsorg::Addon
  module Group
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :basename, type: String
      field :overview, type: String
      permit_params :basename, :overview

      validates :basename, format: { with: /\A[\w\-]+\z/ }, uniqueness: true, allow_blank: true
      before_save :set_basename
    end

    private

    def set_basename
      return if basename.present?
      self.basename = "g#{id}"
    end
  end
end
