class Gws::Presence::ResetJob < Gws::ApplicationJob
  def perform
    Rails.logger.info "#{site.name}の在席ステータスをリセット開始"

    each_user do |user|
      presence = user.user_presence(site)
      next if presence.nil?

      state = reset[presence.state]
      next if state.nil?

      presence.state = state
      presence.save
    end

    Rails.logger.info "#{site.name}の在席ステータスをリセット完了"
  end

  private

  def reset
    @reset ||= ::SS.config.gws.dig("presence", "reset") || {}
  end

  def each_user(&block)
    group_ids = [site.id]
    group_ids += ::Gws::Group.active.where(name: /^#{site.name}\//).pluck(:id)

    all_user_ids = ::Gws::User.active.in(group_ids: group_ids).pluck(:id)
    all_user_ids.each_slice(100) do |ids|
      ::Gws::User.all.in(id: ids).to_a.each(&block)
    end
  end
end
