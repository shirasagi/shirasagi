module Workflow::Addon
  module Approver
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 50

    attr_accessor :workflow_reset

    included do
      field :workflow_user_id, type: Integer
      field :workflow_state, type: String
      field :workflow_comment, type: String
      field :workflow_approvers, type: Workflow::Extensions::WorkflowApprovers

      permit_params :workflow_user_id, :workflow_state, :workflow_comment
      permit_params :workflow_approvers, :workflow_reset

      validate :validate_workflow_approvers
    end

    public
      def t_state
        if state == "public" || state == "ready"
          I18n.t("views.state.#{state}")
        elsif workflow_state.present?
          I18n.t("views.state.#{workflow_state}")
        elsif state == "closed"
          I18n.t("views.state.#{state}")
        else
          ""
        end
      end

    private
      def validate_workflow_approvers
        if workflow_reset
          self.unset(:workflow_user_id)
          self.unset(:workflow_state)
          self.unset(:workflow_comment)
          self.unset(:workflow_approvers)
        end
        if workflow_state == "request" && workflow_approvers.blank?
          errors.add :workflow_approvers, :not_select
        end
      end
  end
end
