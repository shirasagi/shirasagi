module Webmail::Addon::History
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    after_save :save_history_for_save
    after_destroy :save_history_for_destroy
  end

  def histories
    @histroies ||= Webmail::History.where(model: reference_model, item_id: id)
  end

  def skip_webmail_history
    @skip_webmail_history = true
  end

  private

  def save_history_for_save
    field_changes = changes.presence || previous_changes
    return if field_changes.blank?

    if field_changes.key?('_id')
      save_history mode: 'create'
    else
      save_history mode: 'update', updated_fields: field_changes.keys.reject { |s| s =~ /_hash$/ }
    end
  end

  def save_history_for_destroy
    save_history mode: 'delete' # @flagged_for_destroy
  end

  def save_history(overwrite_params = {})
    return if @skip_webmail_history

    Webmail::History.info!(
      :model, @cur_user,
      overwrite_params.reverse_merge(
        name: reference_name,
        model: reference_model,
        item_id: id
      )
    ) rescue nil
  end
end
