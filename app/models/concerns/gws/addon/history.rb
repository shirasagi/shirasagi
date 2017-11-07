module Gws::Addon
  module History
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      after_find :save_history_for_find
      after_save :save_history_for_save
      after_destroy :save_history_for_destroy
    end

    def histories
      @histroies ||= Gws::History.where(model: reference_model, item_id: id)
    end

    def skip_gws_history
      @skip_gws_history = true
    end

    private

    def save_history_for_find
      return if @skip_gws_history

      site = @cur_site
      site ||= self.site rescue nil
      return unless site

      Gws::History.notice!(
        :model, @cur_user, site,
        name: reference_name,
        model: reference_model,
        item_id: id
      ) rescue nil
    end

    def save_history_for_save
      return if @db_changes.blank?

      if @db_changes.key?('_id')
        save_history mode: 'create'
      else
        save_history mode: 'update', updated_fields: @db_changes.keys.reject { |s| s =~ /_hash$/ }
      end
    end

    def save_history_for_destroy
      save_history mode: 'delete' # @flagged_for_destroy
    end

    def save_history(overwrite_params = {})
      return if @skip_gws_history

      site = @cur_site
      site ||= self.site rescue nil
      return unless site

      Gws::History.info!(
        :model, @cur_user, site,
        overwrite_params.reverse_merge(
          name: reference_name,
          model: reference_model,
          item_id: id
        )
      ) rescue nil
    end
  end
end
