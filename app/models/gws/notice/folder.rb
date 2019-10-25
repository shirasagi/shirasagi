class Gws::Notice::Folder
  include SS::Document
  include Gws::Model::Folder
  include Gws::Addon::Notice::ResourceLimitation
  include Gws::Addon::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  member_include_custom_groups
  readable_setting_include_custom_groups

  class << self
    def create_my_folder!(site, group)
      full_name = ''
      depth = 0
      last_folder = nil
      group.name.split('/').each do |part|
        full_name << '/' if full_name.present?
        full_name << part
        depth += 1

        folder = self.site(site).where(name: full_name, depth: depth).first_or_create! do |folder|
          if last_folder
            copy_limits(last_folder, folder)
          else
            set_default_limits(folder)
          end

          group_ids = Gws::Group.all.active.where(name: full_name).pluck(:id)

          conds = []
          conds << { name: full_name }
          conds << { name: /#{::Regexp.escape(full_name)}\// }
          descendants_group_ids = Gws::Group.all.active.where('$and' => [{ '$or' => conds }]).pluck(:id)

          folder.member_group_ids = group_ids
          folder.readable_setting_range = 'select'
          folder.readable_group_ids = descendants_group_ids
          folder.group_ids = group_ids
        end

        last_folder = folder
      end

      last_folder
    end

    def for_post_manager(site, user)
      self.site(site).allow(:read, user, site: site)
    end

    def for_post_editor(site, user)
      or_conds = self.member_conditions(user)
      or_conds += self.readable_conditions(user, site: site)
      self.site(site).where('$and' => [{ '$or' => or_conds }])
    end

    def for_post_reader(site, user)
      or_conds = self.readable_conditions(user, site: site)
      self.site(site).where('$and' => [{ '$or' => or_conds }])
    end

    private

    def copy_limits(source, dest)
      dest.notice_individual_body_size_limit = source.notice_individual_body_size_limit
      dest.notice_total_body_size_limit = source.notice_total_body_size_limit
      dest.notice_individual_file_size_limit = source.notice_individual_file_size_limit
      dest.notice_total_file_size_limit = source.notice_total_file_size_limit
    end

    def set_default_limits(folder)
      %i[
        notice_individual_body_size_limit notice_total_body_size_limit
        notice_individual_file_size_limit notice_total_file_size_limit
      ].each do |attr|
        SS.config.gws.notice["default_#{attr}"].tap do |limit|
          if limit.present?
            folder.send("#{attr}=", limit)
          end
        end
      end
    end
  end

  def for_post_manager?(site, user)
    allowed?(:read, user, site: site)
  end

  def for_post_editor?(site, user)
    member?(user) || for_post_reader?(site, user)
  end

  def for_post_reader?(site, user)
    return true if !readable_setting_present?
    return true if readable_group_ids.any? { |m| user.group_ids.include?(m) }
    return true if readable_member_ids.include?(user.id)
    return true if readable_custom_groups.any? { |m| m.member_ids.include?(user.id) }
    false
  end

  def notices
    Gws::Notice::Post.all.site(site).where(folder_id: id)
  end

  def reclaim!
    set(
      notice_total_body_size: notices.pluck(:text).select(&:present?).map(&:size).sum,
      notice_total_file_size: SS::File.in(id: notices.pluck(:file_ids).flatten).sum(:size)
    )
  end
end
