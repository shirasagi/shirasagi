class Ezine::SentLog
  include SS::Document

  field :email, type: String, metadata: { from: :email }

  belongs_to :page, class_name: "Ezine::Page"
  belongs_to :node, class_name: "Cms::Node"
end
