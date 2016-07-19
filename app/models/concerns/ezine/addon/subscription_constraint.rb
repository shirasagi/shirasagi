module Ezine::Addon
  module SubscriptionConstraint
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :subscription_constraint, type: String
      validates :subscription_constraint, inclusion: { in: %w(optional required), allow_blank: true }
      permit_params :subscription_constraint
      after_save :update_members_subscription
      scope :and_subscription_required, ->{ where(subscription_constraint: 'required') }
    end

    private
      def update_members_subscription
        return unless subscription_requried?

        Cms::Member.site(site).each do |member|
          subscription_ids = member.subscription_ids
          subscription_ids ||= []
          subscription_ids << self.id
          subscription_ids = subscription_ids.uniq
          member.subscription_ids = subscription_ids
          member.save!
        end
      end

    public
      def subscription_constraint_options
        %w(optional required).map { |m| [ I18n.t("inquiry.options.required.#{m}"), m ] }.to_a
      end

      def subscription_requried?
        subscription_constraint == 'required'
      end
  end
end
