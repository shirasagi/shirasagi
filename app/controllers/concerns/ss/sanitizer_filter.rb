module SS::SanitizerFilter
  extend ActiveSupport::Concern

  included do
    before_action :deny_sanitizing_file, only: [:update, :destroy]
  end

  private

  def deny_sanitizing_file
    return unless @item
    return unless @item.try(:sanitizer_state) == 'wait'
    return if @item.try(:updated).to_i < 20.minutes.ago.to_i

    @item.errors.add :base, :sanitizer_waiting
    render html: view_context.error_messages_for(@item), layout: true
  end
end
