module Article::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^article\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    SS::Site.each do |s|
      if s.facebook_access_token.present?
        include Cms::Addon::NodeAutoPostSetting
      elsif s.twitter_consumer_key.present? && s.twitter_consumer_secret.present? \
          && s.twitter_access_token.present? && s.twitter_access_token_secret.present?
        include Cms::Addon::NodeAutoPostSetting
      end
    end
    include Event::Addon::PageList
    include Category::Addon::Setting
    include Cms::Addon::TagSetting
    include Cms::Addon::OpendataRef::Site
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::MaxFileSizeSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "article/page") }
  end
end
