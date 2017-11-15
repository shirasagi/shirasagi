module Cms::Addon
  module ForMemberNode
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :for_member_state, type: String, default: "disabled"

      permit_params :for_member_state

      validates :for_member_state, inclusion: { in: %w(disabled enabled) }
      before_save :check_parents_state
      after_save :set_children_state
      after_save :remove_files_recursively, if: ->{ for_member_enabled? }
    end

    def for_member_state_options
      %w(disabled enabled).map { |v| [I18n.t("ss.options.state.#{v}"), v] }
    end

    def for_member_enabled?
      self.for_member_state == 'enabled'
    end

    def for_member_disabled?
      !for_member_enabled?
    end

    def serve_static_file?
      return false if for_member_enabled?
      super
    end

    private

    def check_parents_state
      p_state = self.parents.any? { |p_node| p_node.try(:for_member_enabled?) }
      self.for_member_state = 'enabled' if p_state
    end

    def set_children_state
      return if self.for_member_disabled?
      self.all_children.each { |c_node| c_node.set(for_member_state: 'enabled') }
    end
  end
end
