module Cms::Addon
  module Line::Message::Cloneable
    extend ActiveSupport::Concern
    extend SS::Addon

    def cloned_name?
      prefix = I18n.t("workflow.cloned_name_prefix")
      name =~ /^\[#{::Regexp.escape(prefix)}\]/
    end

    def copy_and_save(attributes = {})
      item = self.class.new

      # basic
      item.site = site
      item.user = user
      item.name = name
      item.group_ids = group_ids

      # deliver_condition
      item.deliver_condition_state = deliver_condition_state
      item.deliver_condition = deliver_condition
      1.upto(self.class::CHILD_CONDITION_MAX_SIZE) do |i|
        item.send("lower_year#{i}=", item.send("lower_year#{i}"))
        item.send("upper_year#{i}=", item.send("upper_year#{i}"))
        item.send("lower_month#{i}=", item.send("lower_month#{i}"))
        item.send("upper_month#{i}=", item.send("upper_month#{i}"))
      end
      item.deliver_category_ids = deliver_category_ids

      item.attributes = attributes
      return item unless item.save

      templates.map do |template|
        new_template = template.new_clone
        new_template.message = item
        new_template.save
      end
      item
    end
  end
end
