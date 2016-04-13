module Gws::Content::Targetable
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :target, type: String, default: "all"

    permit_params :target

    scope :target_to, ->(user) {
      where("$or" => [
        { target: "all" },
        { target: "group", :group_ids.in => user.group_ids },
        { target: "member", member_ids: user.id }
      ])
    }
  end

  def targetable?
    true
  end

  def target_options
    keys = %w(all group)
    keys << 'member' if fields['member_ids']
    keys.map { |key| [I18n.t("gws.options.target.#{key}"), key] }
  end
end
