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

    folders = criteria.to_a
    id_to_folder_map = folders.index_by(&:id)

    builder = Gws::Notice::FoldersTreeComponent::Base::TreeBuilder.new(items: folders, item_url_p: ->(_) {})
    root_nodes = builder.call

    enum = Enumerator.new do |y|
      traverse_p = ->(nodes) do
        nodes.each do |node|
          folder = id_to_folder_map[node.id]
          y << folder
          traverse_p.call(node.children)
        end
      end
      traverse_p.call(root_nodes)
    end

    drawer.enum(enum, options.merge(model: Gws::Notice::Folder))
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
          criteria = readable_custom_groups(item.member_custom_group_ids)
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
        criteria = readable_groups(item.member_group_ids)
        names = criteria.pluck(:name)
        if truncate
          names = SS::Csv.truncate_overflows(names, "ss.overflow_group")
        end
        names.join("\n")
      end
    end
    drawer.column :member_ids do
      drawer.body do |item|
        criteria = readable_users(item.member_ids)
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
          criteria = readable_custom_groups(item.readable_custom_group_ids)
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
        criteria = readable_groups(item.readable_group_ids)
        names = criteria.pluck(:name)
        if truncate
          names = SS::Csv.truncate_overflows(names, "ss.overflow_group")
        end
        names.join("\n")
      end
    end
    drawer.column :readable_member_ids do
      drawer.body do |item|
        criteria = readable_users(item.readable_member_ids)

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
          criteria = readable_custom_groups(item.custom_group_ids)
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
        criteria = readable_groups(item.group_ids)
        names = criteria.pluck(:name)
        if truncate
          names = SS::Csv.truncate_overflows(names, "ss.overflow_group")
        end
        names.join("\n")
      end
    end
    drawer.column :user_ids do
      drawer.body do |item|
        criteria = readable_users(item.user_ids)
        # uid と email　のうち、最初の nil でないものを抽出
        user_ids = criteria.pluck(:uid, :email).map { |array| array.compact.first }
        if truncate
          user_ids = SS::Csv.truncate_overflows(user_ids, "ss.overflow_user")
        end
        user_ids.join("\n")
      end
    end
  end

  def all_custom_groups
    @all_custom_groups ||= Gws::CustomGroup.site(site).readable(user, site: site).only(:id, :name, :order).to_a
  end

  def id_to_custom_group_map
    @id_to_custom_group_map ||= all_custom_groups.index_by(&:id)
  end

  def readable_custom_groups(custom_group_ids)
    custom_groups = custom_group_ids.map { id_to_custom_group_map[_1] }
    custom_groups.compact!
    custom_groups.sort_by! { [ _1.order || 0, _1.name ] }
    custom_groups
  end

  def all_groups
    @all_groups ||= Gws::Group.site(site).only(:id, :name, :order).to_a
  end

  def id_to_group_map
    @id_to_group_map ||= all_groups.index_by(&:id)
  end

  def readable_groups(group_ids)
    groups = group_ids.map { id_to_group_map[_1] }
    groups.compact!
    groups.sort_by! { [ _1.order || 0, _1.name ] }
    groups
  end

  def all_users
    @all_users ||= begin
      criteria = Gws::User.all
      criteria = criteria.site(site)
      criteria = criteria.active
      criteria = criteria.readable_users(user, site: site)
      criteria.only(:id, :uid, :email, :organization_uid, :title_orders).to_a
    end
  end

  def id_to_user_map
    @id_to_user_map ||= all_users.index_by(&:id)
  end

  def readable_users(user_ids)
    users = user_ids.map { id_to_user_map[_1] }
    users.compact!
    users.sort_by! { [ _1.title_orders.try(:[], site.id.to_s) || 0, _1.organization_uid, _1.uid, _1.id ] }
    users
  end
end
