module Ezine::Addon
  module Subscription
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :subscriptions, class_name: "Cms::Node"
      permit_params subscription_ids: []
      before_validation :ensure_required_subscription
    end

    private
      def ensure_required_subscription
        required_ids = Ezine::Node::MemberPage.site(site || cur_site).and_subscription_required.pluck(:id)
        return if required_ids.blank?
        subscription_ids = self.subscription_ids
        subscription_ids ||= []
        subscription_ids += required_ids
        subscription_ids = subscription_ids.uniq
        self.subscription_ids = subscription_ids
      end
  end
end
