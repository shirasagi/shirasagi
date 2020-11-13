module Tasks
  module Gws
    class Comment
      class << self
        def set_authority
          ::Tasks::Gws::Base.each_sites do |site|
            Rails.logger.info "#{site.name}の回覧板コメントに閲覧権限の設定開始。"
            ::Gws::Circular::SetCommentAuthorityJob.bind(site_id: site.id).perform_now
          end
        end
      end
    end
  end
end
