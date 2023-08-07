class Gws::Presence::ResetJob < Gws::ApplicationJob
  def perform
    Rails.logger.tagged(site.name) do
      Rails.logger.info { "在席ステータスをリセット開始" }

      each_user do |user|
        Rails.logger.tagged("#{user.name}(#{user.uid})") do
          presence = user.user_presence(site)
          next if presence.nil?

          state = reset[presence.state]
          next if state.nil?
          next if presence.state == state

          presence.state = state
          result = presence.save
          if result
            Rails.logger.info { "在席ステータスをリセットしました。" }
          else
            Rails.logger.warn do
              messages = [ "在席ステータスのリセットに失敗しました。" ]
              messages += presence.errors.full_messages
              messages.join("\n")
            end
          end
        rescue => e
          Rails.logger.warn { "#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}" }
        end
      end

      Rails.logger.info { "在席ステータスをリセット完了" }
    end
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
