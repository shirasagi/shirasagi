module Gws::Addon::Circular::BrowsingAuthority
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :browsing_authority, type: String, default: 'all'

    permit_params :browsing_authority

    validates :browsing_authority, inclusion: { in: %w(all author_or_commenter) }
  end

  def browsing_authority_options
    %w(all author_or_commenter).map { |v| [I18n.t("gws/circular.options.browsing_authority.#{v}"), v] }
  end
end
