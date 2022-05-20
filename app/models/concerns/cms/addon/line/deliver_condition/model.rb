module Cms::Addon
  module Line::DeliverCondition::Model
    extend ActiveSupport::Concern

    CHILD_CONDITION_MAX_SIZE = 5

    included do
      1.upto(CHILD_CONDITION_MAX_SIZE) do |i|
        field :"lower_year#{i}", type: Integer
        field :"upper_year#{i}", type: Integer
        field :"lower_month#{i}", type: Integer
        field :"upper_month#{i}", type: Integer
        permit_params :"lower_year#{i}", :"upper_year#{i}"
        permit_params :"lower_month#{i}", :"upper_month#{i}"
      end
      embeds_ids :deliver_categories, class_name: "Cms::Line::DeliverCategory::Category"
      permit_params deliver_category_ids: []
    end

    def each_deliver_categories
      Cms::Line::DeliverCategory::Category.site(site).each_public do |root, children|
        categories = children.select { |child| deliver_category_ids.include?(child.id) }
        yield(root, categories) if categories.present?
      end
    end

    def condition_ages
      years = []
      1.upto(CHILD_CONDITION_MAX_SIZE) do |i|
        lower_year = send("lower_year#{i}")
        upper_year = send("upper_year#{i}")
        lower_month = send("lower_month#{i}")
        upper_month = send("upper_month#{i}")

        if lower_year && upper_year
          lower_month ||= 0
          upper_month ||= 11

          lower_to_upper = (lower_year..upper_year)
          size = lower_to_upper.size
          lower_to_upper.each_with_index do |y, i|
            lm = (i == 0) ? lower_month : 0
            rm = (i == (size - 1)) ? upper_month : 11
            years += (lm..rm).map { |m| [y, m] }
          end
        end
      end
      years.uniq
    end

    def condition_label
      h = []

      # year condition
      h << (1..CHILD_CONDITION_MAX_SIZE).map do |i|
        lower_year = send("lower_year#{i}")
        upper_year = send("upper_year#{i}")
        lower_month = send("lower_month#{i}")
        upper_month = send("upper_month#{i}")
        next unless lower_year && upper_year

        lower = lower_month ? "#{lower_year}歳#{lower_month}ヶ月" : "#{lower_year}歳"
        upper = upper_month ? "#{upper_year}歳#{upper_month}ヶ月" : "#{upper_year}歳"
        (lower == upper) ? lower : "#{lower}〜#{upper}"
      end.compact.join(", ")

      # category condition
      Cms::Line::DeliverCategory::Category.site(site).and_root.and_public.each do |root|
        categories = root.children.and_public.select { |category| deliver_category_ids.include?(category.id) }
        h << categories.map(&:name).join(", ") if categories.present?
      end
      h.select(&:present?).join("\n")
    end

    def extract_multicast_members
      criteria = Cms::Member.site(site).and_enabled
      criteria = criteria.where(:oauth_id.exists => true, oauth_type: "line")
      criteria.where(subscribe_line_message: "active")
    end

    def extract_conditional_members
      criteria = extract_multicast_members

      if deliver_categories.and_public.present?
        cond = []
        each_deliver_categories do |_, children|
          cond << { "deliver_category_ids" => { "$in" => children.map(&:id) } }
        end
        criteria = criteria.and(cond) if cond.present?
      end

      if condition_ages.present?
        members = criteria.to_a.select do |member|
          (condition_ages & member.child_ages).present?
        end
        criteria = Cms::Member.in(id: members.pluck(:id))
      end
      criteria
    end

    def empty_members
      Cms::Member.none
    end

    private

    1.upto(CHILD_CONDITION_MAX_SIZE) do |i|
      define_method("validate_year#{i}") do
        lower_year = send("lower_year#{i}")
        upper_year = send("upper_year#{i}")
        lower_month = send("lower_month#{i}")
        upper_month = send("upper_month#{i}")

        # validate year
        if lower_year && upper_year
          if lower_year > upper_year
            errors.add "upper_year#{i}", :greater_than, count: t("lower_year#{i}")
          else
            # validate month
            if lower_month && upper_month
              if lower_year == upper_year && lower_month > upper_month
                errors.add "upper_month#{i}", :greater_than, count: t("lower_month#{i}")
              end
            elsif lower_month
              errors.add "upper_month#{i}", :blank
            elsif upper_month
              errors.add "lower_month#{i}", :blank
            end
          end
        elsif lower_year
          errors.add "upper_year#{i}", :blank
        elsif upper_year
          errors.add "lower_year#{i}", :blank
        end
      end
    end

    def validate_condition_body
      1.upto(CHILD_CONDITION_MAX_SIZE).each { |i| send("validate_year#{i}") }
      return if errors.present?

      if condition_ages.blank? && deliver_categories.and_public.blank?
        errors.add :base, "配信条件を入力してください"
      end
    end
  end
end
