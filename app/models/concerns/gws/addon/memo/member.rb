module Gws::Addon
  module Memo::Member
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::Member

    included do
      class_variable_set(:@@_member_ids_required, false)
    end

    public

    def sorted_to_members
      return @sorted_to_members if @sorted_to_members

      hash = to_members.map { |m| [m.id, m] }.to_h
      @sorted_to_members = to_member_ids.map { |id| hash[id] }.compact
    end

    def sorted_cc_members
      return @sorted_cc_members if @sorted_cc_members

      hash = cc_members.map { |m| [m.id, m] }.to_h
      @sorted_cc_members = cc_member_ids.map { |id| hash[id] }.compact
    end

    def sorted_bcc_members
      return @sorted_bcc_members if @sorted_bcc_members

      hash = bcc_members.map { |m| [m.id, m] }.to_h
      @sorted_bcc_members = bcc_member_ids.map { |id| hash[id] }.compact
    end

    private

    def validate_presence_member
      return true if draft?
      return true if to_member_ids.present?
      errors.add :to_member_ids, :empty
    end
  end
end
