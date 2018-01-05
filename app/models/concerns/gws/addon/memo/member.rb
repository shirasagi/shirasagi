module Gws::Addon
  module Memo::Member
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::Member

    included do
      embeds_ids :to_members, class_name: "Gws::User"
      embeds_ids :cc_members, class_name: "Gws::User"
      embeds_ids :bcc_members, class_name: "Gws::User"

      permit_params to_member_ids: [], cc_member_ids: [], bcc_member_ids: []

      before_validation :validate_member_ids

      validate :validate_presence_member
    end

    private

    def validate_member_ids
      self.member_ids = (to_member_ids + cc_member_ids + bcc_member_ids).uniq
    end

    def validate_presence_member
      return true if to_member_ids.present?
      errors.add :to_member_ids, :empty
    end

    public

    def display_to
      to_members.map(&:long_name)
    end

    def display_cc
      cc_members.map(&:long_name)
    end

    def display_bcc
      bcc_members.map(&:long_name)
    end
  end
end
