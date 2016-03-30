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
      reminder = @model.where({
        item_collection: attr[:item_collection],
        item_id: attr[:item_id],
        user_id: @cur_user.id,
      }).first
    end

  public
    def create
      item = find_item || @model.new
      item.attributes = get_params

      if item.save
        render inline: I18n.t("gws.reminder.states.entry"), layout: false
      else
        render inline: "Error", layout: false
      end
    end

    def destroy
      item = find_item

      if item.destroy
        render inline: I18n.t("gws.reminder.states.empty"), layout: false
      else
        render inline: "Error", layout: false
      end
    end
end
