module Gws::Addon
  module Memo::Member
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::Member

    included do
      attr_accessor :in_request_mdn

      embeds_ids :to_members, class_name: "Gws::User"
      embeds_ids :cc_members, class_name: "Gws::User"
      embeds_ids :bcc_members, class_name: "Gws::User"
      embeds_ids :request_mdn, class_name: "Gws::User"

      permit_params :in_request_mdn
      permit_params to_member_ids: [], cc_member_ids: [], bcc_member_ids: []

      before_validation :set_member_ids
      before_validation :set_request_mdn
      before_validation :set_send_date

      validate :validate_presence_member
    end

    private

    def set_member_ids
      self.member_ids = (to_member_ids + cc_member_ids + bcc_member_ids).uniq
    end

    def set_request_mdn
      return if in_request_mdn != "1"
      return if send_date.present?
      self.request_mdn_ids = self.member_ids - [@cur_user.id]
    end

    def set_send_date
      now = Time.zone.now
      self.send_date ||= now if state == "public"
      #self.seen[cur_user.id] ||= now if cur_user
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
