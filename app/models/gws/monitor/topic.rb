# "Post" class for BBS. It represents "topic" models.
class Gws::Monitor::Topic
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Monitor::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::Monitor::Category
  include Gws::Addon::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Monitor::BrowsingState

  readable_setting_include_custom_groups

  validates :category_ids, presence: true
  after_validation :set_descendants_updated_with_released, if: -> { released.present? && released_changed? }

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      where({}).order_by(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      where({}).order_by(descendants_updated: key.end_with?('_asc') ? 1 : -1)
    else
      where({})
    end
  }

  def admin_setting_options
    [
        %w(作成者が管理する 1),
        %w(所属で管理する 0)
    ]
  end

  def spec_config_options
    [
        %w(回答者のみ表示する 0),
        %w(他の回答者名を表示する 3),
        %w(他の回答者名と内容を表示する 5)
    ]
  end

  def reminder_start_section_options
    [
        %w(配信直後から表示する 0),
        %w(配信日から1日後に表示 -1),
        %w(配信日から2日後に表示 -2),
        %w(配信日から3日後に表示 -3),
        %w(配信日から4日後に表示 -4),
        %w(配信日から5日後に表示 -5),
        %w(回答期限日の1日前から表示 1),
        %w(回答期限日の2日前から表示 2),
        %w(回答期限日の3日前から表示 3),
        %w(回答期限日の4日前から表示 4),
        %w(回答期限日の5日前から表示 5),
        %w(表示しない -999)
    ]
  end

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  end

  def subscribed_users
    return Gws::User.none if new_record?
    return Gws::User.none if categories.blank?

    conds = []
    conds << { id: { '$in' => categories.pluck(:subscribed_member_ids).flatten } }
    conds << { group_ids: { '$in' => categories.pluck(:subscribed_group_ids).flatten } }

    if Gws::Monitor::Category.subscription_setting_included_custom_groups?
      custom_gropus = Gws::CustomGroup.in(id: categories.pluck(:subscribed_custom_group_ids))
      conds << { id: { '$in' => custom_gropus.pluck(:member_ids).flatten } }
    end

    Gws::User.where('$and' => [ { '$or' => conds } ])
  end

  def sort_options
    %w(updated_desc updated_asc created_desc created_asc).map { |k| [I18n.t("ss.options.sort.#{k}"), k] }
  end

  private

  def set_descendants_updated_with_released
    if descendants_updated.present?
      self.descendants_updated = released if descendants_updated < released
    else
      self.descendants_updated = released
    end
  end
end

