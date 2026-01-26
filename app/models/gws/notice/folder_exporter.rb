class Gws::Notice::FolderExporter
  include ActiveModel::Model

  attr_accessor :site, :user, :criteria, :truncate

  def enum_csv(options = {})
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_basic(drawer)
      draw_resource_limitation(drawer)
      draw_member(drawer)
      draw_readable_setting(drawer)
      draw_group_permission(drawer)
    end

    drawer.enum(criteria, options)
  end

  private

  def draw_basic(drawer)
    drawer.column :id
    drawer.column :name
    drawer.column :depth
    drawer.column :order
    drawer.column :state, type: :label
  end

  def draw_resource_limitation(drawer)
    drawer.column :notice_individual_body_size_limit
    drawer.column :notice_total_body_size_limit
    drawer.column :notice_individual_file_size_limit
    drawer.column :notice_total_file_size_limit
    drawer.column :notice_total_body_size
    drawer.column :notice_total_file_size
  end

  def draw_member(drawer)
    if Gws::Notice::Folder.member_include_custom_groups?
      drawer.column :member_custom_group_ids do
        drawer.body do |item|
          criteria = readable_custom_groups(item.member_custom_groups)
          names = criteria.pluck(:name)
          if truncate
            names = SS::Csv.truncate_overflows(names, "ss.overflow_custom_group")
          end
          names.join("\n")
        end
      end
    end
    drawer.column :member_group_ids do
      drawer.body do |item|
        criteria = readable_groups(item.member_groups)
        names = criteria.pluck(:name)
        if truncate
          names = SS::Csv.truncate_overflows(names, "ss.overflow_group")
        end
        names.join("\n")
      end
    end
    drawer.column :member_ids do
      drawer.body do |item|
        criteria = readable_users(item.members)
        # uid と email　のうち、最初の nil でないものを抽出
        user_ids = criteria.pluck(:uid, :email).map { |array| array.compact.first }
        if truncate
          user_ids = SS::Csv.truncate_overflows(user_ids, "ss.overflow_user")
        end
        user_ids.join("\n")
      end
    end
  end

  def draw_readable_setting(drawer)
    drawer.column :readable_setting_range, type: :label
    if Gws::Notice::Folder.readable_setting_included_custom_groups?
      drawer.column :readable_custom_group_ids do
        drawer.body do |item|
          criteria = readable_custom_groups(item.readable_custom_groups)
          names = criteria.pluck(:name)
          if truncate
            names = SS::Csv.truncate_overflows(names, "ss.overflow_custom_group")
          end
          names.join("\n")
        end
      end
    end
    drawer.column :readable_group_ids do
      drawer.body do |item|
        criteria = readable_groups(item.readable_groups)
        names = criteria.pluck(:name)
        if truncate
          names = SS::Csv.truncate_overflows(names, "ss.overflow_group")
        end
        names.join("\n")
      end
    end
    drawer.column :readable_member_ids do
      drawer.body do |item|
        criteria = readable_users(item.readable_members)

        # uid と email　のうち、最初の nil でないものを抽出
        user_ids = criteria.pluck(:uid, :email).map { |array| array.compact.first }
        if truncate
          user_ids = SS::Csv.truncate_overflows(user_ids, "ss.overflow_user")
        end
        user_ids.join("\n")
      end
    end
  end

  def draw_group_permission(drawer)
    if Gws::Notice::Folder.permission_included_custom_groups?
      drawer.column :custom_group_ids do
        drawer.body do |item|
          criteria = readable_custom_groups(item.custom_groups)
          names = criteria.pluck(:name)
          if truncate
            names = SS::Csv.truncate_overflows(names, "ss.overflow_custom_group")
          end
          names.join("\n")
        end
      end
    end
    drawer.column :group_ids do
      drawer.body do |item|
        criteria = readable_groups(item.groups)
        names = criteria.pluck(:name)
        if truncate
          names = SS::Csv.truncate_overflows(names, "ss.overflow_group")
        end
        names.join("\n")
      end
    end
    drawer.column :user_ids do
      drawer.body do |item|
        criteria = readable_users(item.users)
        # uid と email　のうち、最初の nil でないものを抽出
        user_ids = criteria.pluck(:uid, :email).map { |array| array.compact.first }
        if truncate
          user_ids = SS::Csv.truncate_overflows(user_ids, "ss.overflow_user")
        end
        user_ids.join("\n")
      end
    end
  end

  def readable_custom_groups(base_criteria)
    criteria = base_criteria.site(site)
    criteria = criteria.readable(user, site: site)
    criteria
  end

  def readable_groups(base_criteria)
    criteria = base_criteria.site(site)
    # criteria = criteria.allow(:read, user, site: site)
    criteria
  end

  def readable_users(base_criteria)
    criteria = base_criteria.site(site)
    criteria = criteria.active
    criteria = criteria.readable_users(user, site: site)
    criteria
  end
end
