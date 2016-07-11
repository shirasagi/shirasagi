module Board::Addon
  module PublicScope
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :public_scope, type: String, default: 'group'
      permit_params :public_scope
      validates :public_scope, inclusion: { in: %w(private group public) }, if: ->{ public_scope.present? }
    end

    module ClassMethods
      def and_public_for(member)
        public_criteria_part = { public_scope: 'public' }

        private_criteria_part = { public_scope: 'private', member_id: member.id }

        groups = Member::Group.site(member.site).and_member(member)
        members = groups.map(&:enabled_members).to_a.flatten.uniq
        member_ids = members.map(&:id)
        group_criteria_part = { public_scope: 'group', :member_id.in => member_ids }

        self.or(public_criteria_part, private_criteria_part, group_criteria_part)
      end

      def and_public
        where(public_scope: 'public')
      end
    end

    def public_scope_options
      %w(group public private).map { |m| [ I18n.t("board.options.public_scope.#{m}"), m ] }.to_a
    end
  end
end
