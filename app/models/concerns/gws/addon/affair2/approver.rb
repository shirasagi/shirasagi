module Gws::Addon::Affair2
  module Approver
    extend ActiveSupport::Concern
    extend SS::Addon
    #include SS::Release
    include Workflow::Approver

    included do
      cattr_reader(:approver_user_class) { Gws::User }
      field :state, type: String, default: "closed"
      field :released, type: DateTime
      permit_params :state, :released

      validates :state, presence: true
      validates :released, datetime: true

      validate :validate_workflow_approvers_role, if: -> { workflow_state == Workflow::Approver::WORKFLOW_STATE_REQUEST }
      after_validation :set_released, if: -> { state == "public" }
    end

    def state_options
      %w(public closed).map { |m| [I18n.t("gws/affair2.options.state.#{m}"), m] }
    end

    def status_options
      [ Workflow::Approver::WORKFLOW_STATE_PUBLIC, Workflow::Approver::WORKFLOW_STATE_CLOSED,
        Workflow::Approver::WORKFLOW_STATE_REQUEST, Workflow::Approver::WORKFLOW_STATE_APPROVE,
        Workflow::Approver::WORKFLOW_STATE_PENDING, Workflow::Approver::WORKFLOW_STATE_REMAND ].map do |v|
        [ I18n.t("gws/affair2.options.state.#{v}"), v ]
      end
    end

    def private_show_path
    end

    def workflow_wizard_path
    end

    def workflow_pages_path
    end

    def agent_enabled?
      false
    end

    private

    def set_released
      self.released ||= Time.zone.now
    end

    ## set context in allowed?
    def validate_user(route, users, *actions)
      actions.each do |action|
        unable_users = users.reject do |_, user|
          allowed?(action, user, site: cur_site, adds_error: false)
        end
        unable_users.each do |level, user|
          errors.add :base, "route_approver_unable_to_#{action}".to_sym, route: route.name, level: level, user: user.name
        end
      end
    end

    ## set context in allowed?
    def validate_workflow_approvers_role
      return if new_record?
      return if cur_site.nil?
      return if errors.present?

      # check whether approvers have read permission.
      users = workflow_approvers.map do |approver|
        self.class.approver_user_class.where(id: approver[:user_id]).first
      end
      users = users.select(&:present?)
      users.each do |user|
        errors.add :workflow_approvers, :not_read, name: user.name unless allowed?(:read, user, site: cur_site, adds_error: false)
        errors.add :workflow_approvers, :not_approve, name: user.name unless allowed?(:approve, user, site: cur_site, adds_error: false)
      end
    end
  end
end
