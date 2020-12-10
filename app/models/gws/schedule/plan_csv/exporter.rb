class Gws::Schedule::PlanCsv::Exporter
  include ActiveModel::Model

  attr_accessor :site, :user, :model, :template
  attr_accessor :criteria

  class << self
    def enum_csv(criteria, opts = {})
      opts = opts.dup
      opts[:criteria] = criteria
      new(opts).enum_csv
    end

    def to_csv(criteria, opts = {})
      enum_csv(criteria, opts).to_a.to_csv
    end

    def enum_template_csv(opts = {})
      opts = opts.dup
      opts[:criteria] = Gws::Schedule::Plan.none
      opts[:template] = true
      new(opts).enum_csv
    end
  end

  def enum_csv
    drawer = SS::Csv.draw(:export, context: self) do |drawer|
      draw_basic(drawer)
      draw_reminder(drawer)
      draw_schedule_repeat(drawer)
      draw_notify_setting(drawer)
      draw_markdown(drawer)
      draw_file(drawer)
      draw_schedule_reports(drawer)
      draw_member(drawer)
      draw_schedule_attendance(drawer)
      draw_schedule_facility(drawer)
      draw_schedule_facility_column_values(drawer, select_facilities)
      draw_schedule_approval(drawer)
      draw_readable_setting(drawer)
      draw_group_permission(drawer)
    end

    drawer.enum(self.criteria, cur_site: site, cur_user: user, model: model)
  end

  private

  def select_facilities
    facilities = readable_facilities(Gws::Facility::Item.all)

    if !template
      facility_ids = self.criteria.pluck(:main_facility_id)
      facility_ids.uniq!
      facility_ids.compact!
      facilities = facilities.in(id: facility_ids)
    end

    facilities.order_by(order: 1, name: 1)
  end

  def draw_basic(drawer)
    drawer.column :id
    drawer.column :name
    drawer.column :allday, type: :label
    drawer.column :start_at do
      drawer.body do |item|
        if item.allday?
          I18n.l(item.start_on)
        else
          I18n.l(item.start_at)
        end
      end
    end
    drawer.column :end_at do
      drawer.body do |item|
        if item.allday?
          I18n.l(item.end_on)
        else
          I18n.l(item.end_at)
        end
      end
    end
    drawer.column :category_id do
      drawer.body do |item|
        criteria = Gws::Schedule::Category.all
        criteria = criteria.site(site)
        criteria = criteria.readable(user, site: site)
        criteria = criteria.where(id: item.category_id)

        criteria.pluck(:name).first
      end
    end
    drawer.column :priority, type: :label
    drawer.column :color
  end

  def draw_reminder(drawer)
  end

  def draw_schedule_repeat(drawer)
  end

  def draw_notify_setting(drawer)
    drawer.column :notify_state, type: :label
  end

  def draw_markdown(drawer)
    drawer.column :text_type, type: :label
    drawer.column :text
  end

  def draw_file(drawer)
  end

  def draw_schedule_reports(drawer)
  end

  def draw_member(drawer)
    drawer.column :member_custom_group_ids do
      drawer.body do |item|
        criteria = readable_custom_groups(item.member_custom_groups)
        criteria.pluck(:name).join("\n")
      end
    end
    drawer.column :member_group_ids do
      drawer.body do |item|
        criteria = readable_groups(item.member_groups)
        criteria.pluck(:name).join("\n")
      end
    end
    drawer.column :member_ids do
      drawer.body do |item|
        criteria = readable_users(item.members)
        criteria.pluck(:uid, :email).map { |array| array.compact.first }.join("\n")
      end
    end
  end

  def draw_schedule_attendance(drawer)
    drawer.column :attendance_check_state, type: :label
  end

  def draw_schedule_facility(drawer)
    drawer.column :facility_ids do
      drawer.body do |item|
        criteria = readable_facilities(item.facilities)
        criteria.pluck(:name).join("\n")
      end
    end
    drawer.column :main_facility_id do
      drawer.body do |item|
        criteria = readable_facilities(Gws::Facility::Item.where(id: item.main_facility_id))
        criteria.pluck(:name).join("\n")
      end
    end
  end

  def draw_schedule_facility_column_values(drawer, facilities)
    return if facilities.blank?

    facilities.each do |facility|
      next if facility.columns.blank?

      facility.columns.order_by(order: 1, name: 1).each do |column|
        # Currently, Gws::Column::FileUpload is not supported to export to csv
        next if column.is_a?(Gws::Column::FileUpload)

        drawer.column "#{facility.name}/#{column.name}" do
          drawer.head do
            "#{facility.name}/#{column.name}"
          end
          drawer.body do |item|
            find_facility_column_value(item, facility, column).try do |v|
              v.value
            end
          end
        end
      end
    end
  end

  def draw_schedule_approval(drawer)
    drawer.column :approval_member_ids do
      drawer.body do |item|
        criteria = item.approval_members
        criteria = criteria.site(site)
        criteria = criteria.active
        criteria = criteria.readable(user, site: site)

        criteria.pluck(:uid, :email).map { |array| array.compact.first }.join("\n")
      end
    end
  end

  def draw_readable_setting(drawer)
    drawer.column :readable_setting_range, type: :label
    drawer.column :readable_custom_group_ids do
      drawer.body do |item|
        criteria = readable_custom_groups(item.readable_custom_groups)
        criteria.pluck(:name).join("\n")
      end
    end
    drawer.column :readable_group_ids do
      drawer.body do |item|
        criteria = readable_groups(item.readable_groups)
        criteria.pluck(:name).join("\n")
      end
    end
    drawer.column :readable_member_ids do
      drawer.body do |item|
        criteria = readable_users(item.readable_members)
        criteria.pluck(:uid, :email).map { |array| array.compact.first }.join("\n")
      end
    end
  end

  def draw_group_permission(drawer)
    drawer.column :custom_group_ids do
      drawer.body do |item|
        criteria = readable_custom_groups(item.custom_groups)
        criteria.pluck(:name).join("\n")
      end
    end
    drawer.column :group_ids do
      drawer.body do |item|
        criteria = readable_groups(item.groups)
        criteria.pluck(:name).join("\n")
      end
    end
    drawer.column :user_ids do
      drawer.body do |item|
        criteria = readable_users(item.users)
        criteria.pluck(:uid, :email).map { |array| array.compact.first }.join("\n")
      end
    end
    drawer.column :permission_level
  end

  def find_facility_column_value(item, facility, column)
    return if item.main_facility_id != facility.id

    item.facility_column_values.where(column_id: column.id).first
  end

  def readable_facilities(base_criteria)
    criteria = base_criteria.site(site)
    criteria = criteria.active
    criteria = criteria.readable(user, site: site)
    criteria
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
