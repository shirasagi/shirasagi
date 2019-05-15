class Gws::Schedule::Todo
  include SS::Document
  include Gws::Referenceable
  include Gws::Reference::User
  include Gws::Reference::Site
  include Gws::Schedule::Priority
  include Gws::Schedule::Colorize
  include Gws::Schedule::Planable
  include Gws::Schedule::Cloneable
  include Gws::Schedule::CalendarFormat
  include Gws::Addon::Reminder
  include Gws::Addon::Schedule::Repeat
  include Gws::Addon::Memo::NotifySetting
  include Gws::Addon::Schedule::Todo::Category
  include Gws::Addon::Schedule::Todo::CommentPost
  include Gws::Addon::Discussion::Todo
  include SS::Addon::Markdown
  include Gws::Addon::File
  include Gws::Addon::Schedule::Todo::Member
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission
  include Gws::Addon::History

  member_include_custom_groups
  permission_include_custom_groups
  readable_setting_include_custom_groups

  field :color, type: String
  field :todo_state, type: String, default: 'unfinished'
  field :achievement_rate, type: Integer

  permit_params :color, :deleted, :achievement_rate

  before_validation :set_todo_state

  validates :todo_state, inclusion: { in: %w(unfinished progressing finished), allow_blank: true }
  validates :achievement_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100, allow_blank: true }

  def finished?
    todo_state == 'finished'
  end

  scope :custom_order, ->(key) {
    if key.start_with?('created_')
      all.reorder(created: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('updated_')
      all.reorder(updated: key.end_with?('_asc') ? 1 : -1)
    elsif key.start_with?('end_at_')
      all.reorder(end_at: key.end_with?('_asc') ? 1 : -1)
    else
      all
    end
  }

  def reminder_user_ids
    member_ids
  end

  # override Gws::Addon::Reminder#reminder_url
  def reminder_url(*args)
    # ret = super
    name = reference_model.tr('/', '_') + '_readable_path'
    [name, id: id, site: site_id]
  end

  def calendar_format(user, site)
    result = super
    result[:title] = I18n.t('gws/schedule/todo.finish_mark') + result[:title] if finished?
    result[:className] = [result[:className], 'fc-event-todo'].flatten
    result
  end

  def private_plan?(user)
    return false if readable_custom_group_ids.present?
    return false if readable_group_ids.present?
    readable_member_ids == [user.id] && member_ids == [user.id]
  end

  def attendance_check_plan?
    false
  end

  def approval_check_plan?
    false
  end

  def active?
    now = Time.zone.now
    return false if deleted.present? && deleted < now
    true
  end

  def todo_state_options
    %w(unfinished progressing finished).map { |v| [I18n.t("gws/schedule/todo.options.todo_state.#{v}"), v] }
  end

  def sort_options
    %w(end_at_asc end_at_desc updated_desc updated_asc created_desc created_asc).map do |k|
      [I18n.t("gws/schedule/todo.options.sort.#{k}"), k]
    end
  end

  def subscribed_users
    return Gws::User.none if new_record?

    ids = member_ids
    ids += Gws::CustomGroup.in(id: member_custom_group_ids).pluck(:member_ids).flatten
    ids.uniq!
    Gws::User.in(id: ids)
  end

  def set_todo_state
    if achievement_rate.blank? || achievement_rate <= 0
      self.todo_state = "unfinished"
    elsif achievement_rate >= 100
      self.todo_state = "finished"
    else
      self.todo_state = "progressing"
    end
  end

  class << self
    def search(params)
      criteria = all.search_keyword(params)
      criteria = criteria.search_todo_state(params)
      criteria = criteria.search_start_end(params)
      criteria = criteria.search_member_ids(params)
      criteria = criteria.search_category(params)
      criteria
    end

    def search_keyword(params)
      return all if params.blank? || params[:keyword].blank?
      all.keyword_in(params[:keyword], :name, :text)
    end

    def search_todo_state(params)
      todo_state = params[:todo_state].presence rescue nil

      if todo_state.blank? || todo_state == 'all'
        all
      elsif todo_state == "except_finished"
        all.not_in(todo_state: %w(finished))
      else
        all.where(todo_state: todo_state)
      end
    end

    def search_start_end(params)
      return all if params.blank?

      criteria = all
      if params[:start].present?
        criteria = criteria.gte(end_at: params[:start])
      end
      if params[:end].present?
        criteria = criteria.lte(start_at: params[:end])
      end
      criteria
    end

    def search_member_ids(params)
      return all if params.blank? || params[:member_ids].blank?

      cur_site = params[:cur_site]
      or_cond = []

      member_ids = Array[params[:member_ids]].flatten.compact.map(&:to_i).uniq
      members = Gws::User.active.site(cur_site).in(id: member_ids)
      return all if members.blank?

      or_cond << { member_ids: members.pluck(:id) }

      group_ids = members.pluck(:group_ids).flatten.compact.uniq
      groups = Gws::Group.active.site(cur_site).in(id: group_ids)
      if groups.present?
        or_cond << { member_group_ids: groups.pluck(:id) }
      end

      if member_include_custom_groups?
        custom_groups = Gws::CustomGroup.site(cur_site).any_members(members)
        if custom_groups.present?
          or_cond << { member_custom_group_ids: custom_groups.pluck(:id) }
        end
      end

      where("$and" => [{ "$or" => or_cond }])
    end

    def search_category(params)
      return all if params.blank? || params[:category_id].blank?

      cur_site = params[:cur_site]
      cur_user = params[:cur_user]

      category = Gws::Schedule::TodoCategory.site(cur_site).
        readable(cur_user, site: cur_site).
        where(id: params[:category_id]).
        first.root
      return none if category.blank?

      children = Gws::Schedule::TodoCategory.site(cur_site).
        readable(cur_user, site: cur_site).
        where(name: /^#{::Regexp.escape(category.name)}\//)

      where(:category_ids.in => children.pluck(:id) + [ category.id ])
    end

    def readable_or_manageable(user, opts = {})
      or_cond = Array[readable_conditions(user, opts)].flatten.compact
      or_cond << allow_condition(:read, user, site: opts[:site])
      where("$and" => [{ "$or" => or_cond }])
    end

    def todo_state_filter_options
      %w(unfinished progressing finished except_finished all).map do |v|
        [ I18n.t("gws/schedule/todo.options.todo_state_filter.#{v}"), v ]
      end
    end

    def todo_grouping_options
      %w(none category user end_at).map do |v|
        [ I18n.t("gws/schedule/todo.options.grouping.#{v}"), v ]
      end
    end

    def group_by_user(site: )
      # load all items
      items = self.all.to_a

      expanded = []
      items.each do |item|
        expanded += item.overall_members.map do |user|
          title_order =  user.title_orders.present? ? user.title_orders[site.id.to_s] || 0 : 0
          [ title_order, user.organization_uid.presence || '', user.uid.presence || '', user, item ]
        end
      end

      expanded.sort! do |lhs, rhs|
        # 0: title's order, this field is descending order
        cmp = rhs[0] <=> lhs[0]
        # 1: organization uid, this field is ascending order
        cmp = lhs[1] <=> rhs[1] if cmp == 0
        # 2: uid, this field is ascending order
        cmp = lhs[2] <=> rhs[2] if cmp == 0
        # final result
        cmp
      end

      last_header = nil
      users_items = []
      expanded.each do |_title_order, _organization_uid, _uid, user, item|
        if last_header.nil?
          last_header = user.long_name
          users_items << item
          next
        end

        if last_header != user.long_name
          yield last_header, users_items

          last_header = user.long_name
          users_items.clear
          users_items << item
          next
        end

        users_items << item
      end

      if users_items.present?
        yield last_header, users_items
      end
    end

    def group_by_end_at(today: nil)
      # load all items
      items = self.all.to_a

      today ||= Time.zone.now
      today = today.beginning_of_day
      tomorrow = today + 1.day
      day_after_tomorrow = tomorrow + 1.day

      out_dated_items = items.select { |item| item.end_at < today }
      if out_dated_items.present?
        yield I18n.t("gws/schedule/todo.header.out_dated"), out_dated_items
      end

      today_items = items.select { |item| today <= item.end_at && item.end_at < tomorrow }
      if today_items.present?
        yield "#{I18n.t("gws/schedule/todo.header.today")} - #{I18n.l(today.to_date)}", today_items
      end

      tomorrow_items = items.select { |item| tomorrow <= item.end_at && item.end_at < day_after_tomorrow }
      if tomorrow_items.present?
        yield "#{I18n.t("gws/schedule/todo.header.tomorrow")} - #{I18n.l(tomorrow.to_date)}", tomorrow_items
      end

      day_after_tomorrow_items = items.select { |item| day_after_tomorrow <= item.end_at }
      if day_after_tomorrow_items.present?
        yield I18n.t("gws/schedule/todo.header.day_after_tomorrow"), day_after_tomorrow_items
      end
    end

    def group_by_category(site: , user: )
      # load all items
      items = self.all.to_a

      expanded = []
      items.each do |item|
        cates = item.categories.readable(user, site: site)
        if cates.present?
          expanded += cates.map do |cate|
            [ cate.present? ? cate.hierarical_orders : nil, cate, item ]
          end
        else
          expanded << [ nil, nil, item ]
        end
      end

      expanded.sort! do |lhs, rhs|
        # 0: title's order, this field is descending order
        cmp = (lhs[0] || []) <=> (rhs[0] || [])
        # final result
        cmp
      end

      last_header = nil
      last_cate = nil
      cate_items = []
      expanded.each do |_hierarical_orders, cate, item|
        cate_name = cate.try(:name) || ""

        if last_header.nil?
          last_header = cate_name
          last_cate = cate
          cate_items << item
          next
        end

        if last_header != cate_name
          yield last_header, cate_items, last_cate

          last_header = cate_name
          last_cate = cate
          cate_items.clear
          cate_items << item
          next
        end

        cate_items << item
      end

      if cate_items.present?
        yield last_header, cate_items, last_cate
      end
    end
  end
end
