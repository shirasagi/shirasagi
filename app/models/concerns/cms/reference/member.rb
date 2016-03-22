module Cms::Reference
  module Member
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_member

    included do
      belongs_to :member, class_name: "Cms::Member"
      before_validation :set_member_id, if: ->{ @cur_member }
    end

    private
    def set_member_id
      self.member_id ||= @cur_member.id
    end
  end
end
