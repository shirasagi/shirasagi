class SS::Migration20190513130500
  include SS::Migration::Base

  depends_on "20190510000000"

  def change
    Gws::Memo::Message.create_indexes
    Gws::Memo::Message.each do |message|
      message.in_path = {}
      message.user_settings = message.member_ids.collect do |member_id|
        if message.filtered[member_id.to_s].present?
          matched_filter = Gws::Memo::Filter.site(message.site).where(user_id: member_id).enabled.detect{ |f| f.match?(message) }
          message.in_path[member_id.to_s] = matched_filter.path if matched_filter
          message.filtered[member_id.to_s] = Time.zone.now
        end
        message.in_path[member_id.to_s] ||= message[:path].try(:[], member_id.to_s)
        seen_at = (message.user_settings_was.presence || []).find{ |setting| setting['user_id'] == member_id }.try(:[], 'seen_at')
        seen_at ||= message[:seen].try(:[], member_id.to_s)
        { 'user_id' => member_id, 'path' => message.in_path[member_id.to_s], 'seen_at' => seen_at }
      end
      message.update
    end
  end
end
