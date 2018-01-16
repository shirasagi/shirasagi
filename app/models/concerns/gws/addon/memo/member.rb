module Gws::Addon
  module Memo::Member
    extend ActiveSupport::Concern
    extend SS::Addon
    include Gws::Member

    included do
      class_variable_set(:@@_member_ids_required, false)
    end

    private

    def validate_presence_member
      return true if draft?
      return true if to_member_ids.present?
      errors.add :to_member_ids, :empty
    end
  end
end
