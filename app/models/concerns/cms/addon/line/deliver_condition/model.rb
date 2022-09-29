module Cms::Addon
  module Line::DeliverCondition::Model
    extend ActiveSupport::Concern

    included do
      embeds_ids :deliver_categories, class_name: "Cms::Line::DeliverCategory::Base"
      permit_params deliver_category_ids: []
    end

    def each_deliver_categories
      Cms::Line::DeliverCategory::Category.site(site).each_public do |root, children|
        categories = children.select { |child| deliver_category_ids.include?(child.id) }
        yield(root, categories)
      end
    end

    def condition_label
      h = []
      Cms::Line::DeliverCategory::Category.site(site).and_root.and_public.each do |root|
        categories = root.children.and_public.select { |category| deliver_category_ids.include?(category.id) }
        h << "#{root.name}: #{categories.map(&:name).join(", ")}" if categories.present?
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
          next if children.blank?
          cond << { "deliver_category_ids" => { "$in" => children.map(&:id) } }
        end
        criteria = criteria.and(cond) if cond.present?
      end
      criteria
    end

    def empty_members
      Cms::Member.none
    end

    private

    def validate_condition_body
      return if deliver_categories.present?
      errors.add :base, "配信条件を入力してください"
    end
  end
end
