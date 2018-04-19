module MailPage::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^mail_page\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::EditorSetting
    include Event::Addon::PageList
    include MailPage::Addon::MailSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::ChildList

    default_scope ->{ where(route: "mail_page/page") }
  end
end
