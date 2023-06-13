# 権限判定用モデル
module Cms::SnsPost
  class Twitter
    include Cms::SitePermission

    set_permission_name "cms_page_twitter_posts", :use
  end

  class Line
    include Cms::SitePermission

    set_permission_name "cms_page_line_posts", :use
  end
end
