module Gws::Addon::Affair
  module Approver
    extend ActiveSupport::Concern
    extend SS::Addon
    include Workflow::Approver
    include Workflow::MemberApprover

    def status
      return 'approve' if state == 'approve'
      return 'draft' if workflow_state == 'cancelled'
      return workflow_state if workflow_state.present?
      return 'draft' if state == 'closed'
      state
    end

    def status_options
      I18n.t("gws/affair.options.status").map { |k, v| [v, k] }
    end

    def workflow_state_options
      %w(all approve request).map do |v|
        [I18n.t("gws/workflow.options.file_state.#{v}"), v]
      end
    end

    def editable?(user, opts)
      editable = allowed?(:edit, user, opts) && !workflow_requested?
      return editable if editable

      if workflow_requested?
        workflow_approver_editable?(user)
      end
    end

    def destroyable?(user, opts)
      allowed?(:delete, user, opts) && !workflow_requested?
    end

    def agent_enabled?
      return false
    end
  end
end
