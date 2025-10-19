class Guide2::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^guide2\//) }
  end

  class Question
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Guide2::QuestionList

    default_scope ->{ where(route: "guide2/question") }
  end
end
