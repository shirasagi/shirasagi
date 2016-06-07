module Cms::Reference
  module Member
    extend ActiveSupport::Concern
    extend SS::Translation

    attr_accessor :cur_member

    included do
      belongs_to :member, class_name: "Cms::Member"
      before_validation :set_member_id, if: ->{ @cur_member }

      scope :member, ->(member) { where(member_id: member.id) }
    end

    public
      def contributor
        member ? member.name : user.name
      rescue
        nil
      end

    private
      def set_member_id
        self.member_id ||= @cur_member.id
      end
  end
end
