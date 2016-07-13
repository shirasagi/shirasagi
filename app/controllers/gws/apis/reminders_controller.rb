class Gws::Apis::RemindersController < ApplicationController
  include Gws::ApiFilter
  include Gws::CrudFilter

  model Gws::Reminder

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site }
    end

    def set_item
    end

    def permit_fields
      @model.permitted_fields
    end

    def find_item
      attr = get_params
      reminder = @model.where(
        site_id: @cur_site.id,
        user_id: @cur_user.id,
        model: attr[:model],
        item_id: attr[:item_id]
      ).first
    end

  public
    def create
      item = find_item || @model.new
      item.attributes = get_params
      item.read_at = Time.zone.now

      if item.save
        render inline: I18n.t("gws.reminder.states.entry"), layout: false
      else
        render inline: "Error", layout: false
      end
    end

    def destroy
      item = find_item

      if item.blank? || item.destroy
        render inline: I18n.t("gws.reminder.states.empty"), layout: false
      else
        render inline: "Error", layout: false
      end
    end

    def notification
      item = find_item
      raise "404" if item.blank?

      notification = item.notifications.first
      notification = item.notifications.new unless notification
      notification.attributes = params.require(:item).permit(:in_notify_before)

      if notification.valid? && item.save
        render inline: I18n.t("gws.reminder.states.entry"), layout: false
      else
        render inline: "Error", layout: false
      end
    end
end
