# "Post" class for BBS. It represents "topic" models.
class Gws::Monitor::Topic
  include Gws::Referenceable
  include Gws::Monitor::Postable
  include Gws::Addon::Monitor::Contributor
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Monitor::DescendantsFileInfo
  include Gws::Addon::Monitor::Category
  include Gws::Addon::Monitor::Release
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History
  include Gws::Monitor::BrowsingState

  readable_setting_include_custom_groups

  field :article_state, type: String, default: 'open'
  field :deleted, type: DateTime

  validates :deleted, datetime: true
  validates :article_state, inclusion: { in: %w(open closed) }

  # indexing to elasticsearch via companion object
  around_save ::Gws::Elasticsearch::Indexer::MonitorTopicJob.callback
  around_destroy ::Gws::Elasticsearch::Indexer::MonitorTopicJob.callback

  permit_params :deleted
  permit_params :article_state

  #validates :category_ids, presence: true
  after_validation :set_descendants_updated_with_released, if: -> { released.present? && released_changed? }
  after_destroy :remove_zip

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      where({}).order_by(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      where({}).order_by(descendants_updated: key.end_with?('_asc') ? 1 : -1)
    else
      where({})
    end
  }

  scope :and_admins, ->(user) {
    where("$and" => [
        { "$or" => [{ :user_ids.in => [user.id] }, { :group_ids.in => user.group_ids }] }
    ])
  }

  def download_root_path
    "#{Rails.root}/private/files/gws_monitors/"
  end

  def zip_path
    self.download_root_path + id.to_s.split(//).join("/") + "/_/#{id}"
  end

  def active?
    return true unless deleted.present? && deleted < Time.zone.now
    false
  end

  def active
    update_attributes(deleted: nil)
  end

  def disable
    update_attributes(deleted: Time.zone.now) if deleted.blank? || deleted > Time.zone.now
  end

  def closed?
    article_state == 'closed'
  end

  def unanswered?(groupid)
    if closed?
      case state_of_the_answers_hash[groupid.to_s]
      when "public", "preparation", nil
        I18n.t("gws/monitor.options.state.closed")
      end
    end
  end

  def article_state_name
    I18n.t("gws/monitor.options.article_state." + article_state)
  end

  def state_name(groupid)
    return I18n.t("gws/monitor.options.state.no_state") if state_of_the_answers_hash[groupid.to_s].blank?
    I18n.t("gws/monitor.options.state." + state_of_the_answers_hash[groupid.to_s])
  end

  def spec_config_options
    [
        [I18n.t('gws/monitor.options.spec_config.my_group'), '0'],
        [I18n.t('gws/monitor.options.spec_config.other_groups'), '3'],
        [I18n.t('gws/monitor.options.spec_config.other_groups_and_contents'), '5']
    ]
  end

  def reminder_start_section_options
    [
        [I18n.t('gws/monitor.options.reminder_start_section.post'), '0'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_one_day_after'), '-1'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_two_days_after'), '-2'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_three_days_after'), '-3'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_four_days_after'), '-4'],
        [I18n.t('gws/monitor.options.reminder_start_section.post_five_days_after'), '-5'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_one_day_ago'), '1'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_two_days_ago'), '2'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_three_days_ago'), '3'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_four_days_ago'), '4'],
        [I18n.t('gws/monitor.options.reminder_start_section.due_date_five_days_ago'), '5'],
        [I18n.t('gws/monitor.options.reminder_start_section.hide'), '-999']
    ]
  end

  def updated?
    created.to_i != updated.to_i || created.to_i != descendants_updated.to_i
  end

  def subscribed_groups
    return Gws::Group.none if new_record?
    return Gws::Group.none if attend_group_ids.blank?

    conds = [{ id: { '$in' => attend_group_ids.flatten } }]

    Gws::Group.where('$and' => [ { '$or' => conds } ])
  end

  def sort_options
    %w(updated_desc updated_asc created_desc created_asc).map { |k| [I18n.t("ss.options.sort.#{k}"), k] }
  end

  def comment(groupid)
    children.where(user_group_id: groupid)
  end

  def answer_count_admin
    answered = state_of_the_answers_hash.count{ |k, v| v.match(/answered|question_not_applicable/) }
    return "(#{answered}/#{attend_group_ids.count})"
  end

  def answer_count(cur_group)
    if attend_group_ids.include?(cur_group.id)
      if spec_config != '0'
        answered = state_of_the_answers_hash.count{ |k, v| v.match(/answered|question_not_applicable/) }
        return "(#{answered}/#{attend_group_ids.count})"
      else
        answered = state_of_the_answers_hash[cur_group.id.to_s].match(/answered|question_not_applicable/)
        return "(#{answered ? 1 : 0}/1)"
      end
    end
    return "(0/0)"
  end

  def to_csv
    CSV.generate do |data|
      data << I18n.t('gws/monitor.csv')

      subscribed_groups.each do |group|
        post = comment(group.id).last
        data << [
            id,
            name,
            unanswered?(group.id) ? unanswered?(group.id) : state_name(group.id),
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

  private

  def set_descendants_updated_with_released
    if descendants_updated.present?
      self.descendants_updated = released if descendants_updated < released
    else
      self.descendants_updated = released
    end
  end
end
