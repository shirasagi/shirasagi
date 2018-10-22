class Gws::Monitor::Topic
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Monitor::Group
  include Gws::Addon::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::Monitor::Category
  include Gws::Addon::Monitor::Release
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  # include Gws::Monitor::BrowsingState

  readable_setting_include_custom_groups

  field :answer_state_hash, type: Hash
  field :article_state, type: String, default: 'open'
  field :deleted, type: DateTime

  field :notice_state, type: String
  field :notice_at, type: DateTime

  permit_params :notice_state

  before_validation :set_answer_state_hash
  before_validation :set_notice_at

  validates :deleted, datetime: true
  validates :article_state, inclusion: { in: %w(open closed) }

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MonitorTopicJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MonitorTopicJob.callback

  #validates :category_ids, presence: true
  after_validation :set_descendants_updated_with_released, if: -> { released.present? && released_changed? }
  after_destroy :remove_zip

  scope :custom_order, ->(key) {
    key ||= 'due_date_desc'
    if key.start_with?('created_')
      reorder(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      reorder(descendants_updated: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('released_')
      reorder(released: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('due_date_')
      reorder(due_date: key.end_with?('_asc') ? 1 : -1)
    end
  }

  scope :and_unanswered, ->(group) do
    where("answer_state_hash.#{group.id}" => { '$nin' => %w(question_not_applicable answered) })
  end

  scope :and_answered, ->(group) do
    where("answer_state_hash.#{group.id}" => { '$in' => %w(question_not_applicable answered) })
  end

  scope :and_noticed, ->(now = Time.zone.now) do
    lte(notice_at: now)
  end

  def article_state_options
    %w(open closed).map do |v|
      [I18n.t("gws/monitor.options.article_state.#{v}"), v]
    end
  end

  def notice_state_options
    # [
    #   [I18n.t('gws/monitor.options.notice_state.post'), '0'],
    #   [I18n.t('gws/monitor.options.notice_state.post_one_day_after'), '-1'],
    #   [I18n.t('gws/monitor.options.notice_state.post_two_days_after'), '-2'],
    #   [I18n.t('gws/monitor.options.notice_state.post_three_days_after'), '-3'],
    #   [I18n.t('gws/monitor.options.notice_state.post_four_days_after'), '-4'],
    #   [I18n.t('gws/monitor.options.notice_state.post_five_days_after'), '-5'],
    #   [I18n.t('gws/monitor.options.notice_state.due_date_one_day_ago'), '1'],
    #   [I18n.t('gws/monitor.options.notice_state.due_date_two_days_ago'), '2'],
    #   [I18n.t('gws/monitor.options.notice_state.due_date_three_days_ago'), '3'],
    #   [I18n.t('gws/monitor.options.notice_state.due_date_four_days_ago'), '4'],
    #   [I18n.t('gws/monitor.options.notice_state.due_date_five_days_ago'), '5'],
    #   [I18n.t('gws/monitor.options.notice_state.hide'), '-999']
    # ]
    %w(
      from_now 1_day_from_released 2_days_from_released 3_days_from_released 4_days_from_released 5_days_from_released
      1_day_before_due_date 2_days_before_due_date 3_days_before_due_date 4_days_before_due_date 5_days_before_due_date
    ).map do |v|
      [I18n.t("gws/monitor.options.notice_state.#{v}"), v]
    end
  end

  def download_root_path
    "#{SS::File.root}/gws_monitors/"
  end

  def zip_path
    self.download_root_path + id.to_s.split(//).join("/") + "/_/#{id}"
  end

  def active?
    deleted.blank? || deleted > Time.zone.now
  end

  def closed?
    article_state == 'closed'
  end

  def answer_state_name(group)
    answered_state = answer_state_hash[group.id.to_s]
    if answered_state.blank?
      I18n.t("gws/monitor.options.answer_state.no_state")
    else
      I18n.t("gws/monitor.options.answer_state.#{answered_state}")
    end
  end

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  end

  def sort_options
    %w(due_date_desc due_date_asc released_desc released_asc updated_desc updated_asc created_desc created_asc).map do |k|
      [I18n.t("gws/monitor.options.sort.#{k}"), k]
    end
  end

  def comment(groupid)
    children.where(user_group_id: groupid)
  end

  def answer_count_admin
    answered = answer_state_hash.count { |k, v| v.match(/answered|question_not_applicable/) }
    return "(#{answered}/#{attend_group_ids.count})"
  end

  def answer_count(cur_group)
    if attend_group_ids.include?(cur_group.id)
      if spec_config != 'my_group'
        answered = answer_state_hash.count{ |k, v| v.match(/answered|question_not_applicable/) }
        return "(#{answered}/#{attend_group_ids.count})"
      else
        answered = answer_state_hash[cur_group.id.to_s].match(/answered|question_not_applicable/)
        return "(#{answered ? 1 : 0}/1)"
      end
    end
    return "(0/0)"
  end

  def to_csv
    CSV.generate do |data|
      data << I18n.t('gws/monitor.csv')

      attend_groups.each do |group|
        post = comment(group.id).last
        data << [
            id,
            name,
            answer_state_name(group),
            group.name,
            post.try(:contributor_name),
            post.try(:text),
            post.try(:updated) ? post.updated.strftime('%Y/%m/%d %H:%M') : ''
        ]
      end
    end
  end

  def create_download_directory(download_dir)
    FileUtils.mkdir_p(download_dir) unless Dir.exist?(download_dir)
  end

  def create_zip(zipfile, group_items, owner_items)
    if File.exist?(zipfile)
      return if self.updated < File.stat(zipfile).mtime
      File.unlink(zipfile) if self.updated > File.stat(zipfile).mtime
    end

    Zip::File.open(zipfile, Zip::File::CREATE) do |zip_file|
      group_items.each do |groupssfile|
        if File.exist?(groupssfile[1].path)
          zip_file.add(NKF::nkf('-sx --cp932', groupssfile[0] + "_" + groupssfile[1].name), groupssfile[1].path)
        end
      end

      owner_items.each do |ownerssfile|
        if File.exist?(ownerssfile[1].path)
          zip_file.add(NKF::nkf('-sx --cp932', "own" + ownerssfile[0] + "_" + ownerssfile[1].name), ownerssfile[1].path)
        end
      end
    end
  end

  def remove_zip
    Fs.rm_rf self.zip_path if File.exist?(self.zip_path)
  end

  def due_date_over?(group, now = Time.zone.now)
    answered_state = answer_state_hash[group.id.to_s]
    return if %w(answered question_not_applicable).include?(answered_state)
    return if due_date.blank?
    due_date < now
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

  private

  def set_descendants_updated_with_released
    if descendants_updated.present?
      self.descendants_updated = released if descendants_updated < released
    else
      self.descendants_updated = released
    end
  end

  def set_answer_state_hash
    prev_hash = answer_state_hash.presence || {}
    new_hash = self.attend_group_ids.map do |group_id|
      g = group_id.to_s
      if prev_hash[g]
        [g, prev_hash[g]]
      else
        [g, "preparation"]
      end
    end

    self.answer_state_hash = new_hash.to_h
  end

  def set_notice_at
    case notice_state
    when 'from_now'
      self.notice_at = ::Time::EPOCH
    when *%w(1_day_from_released 2_days_from_released 3_days_from_released 4_days_from_released 5_days_from_released)
      term, = notice_state.split('_')
      self.notice_at = (released || created) + Integer(term).days
    when *%w(1_day_before_due_date 2_days_before_due_date 3_days_before_due_date 4_days_before_due_date 5_days_before_due_date)
      term, = notice_state.split('_')
      if due_date.present?
        self.notice_at = due_date - Integer(term).days
      else
        self.notice_at = nil
      end
    else
      self.notice_at = nil
    end
  end
end
