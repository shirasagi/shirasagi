module Tasks
  module Gws
    class Presence
      extend Tasks::Gws::Base

      class << self
        def reset
          @reset = SS.config.gws.dig("presence", "reset") || {}

          each_sites do |site|
            Rails.logger.info "#{site.name}の在籍ステータスをリセット開始"

            group_ids = [site.id]
            group_ids += ::Gws::Group.where(name: /^#{site.name}\//).pluck(:id)

            user_ids = ::Gws::User.in(group_ids: group_ids).pluck(:id)
            user_ids.each do |id|
              user = ::Gws::User.find(id) rescue nil
              next if user.nil?

              item = user.user_presence(site)
              next if item.nil?

              state = @reset[item.state]
              next if state.nil?

              item.state = state
              item.save
            end
          end
        end
      end
    end
  end
end
