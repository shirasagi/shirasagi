class Ezine::Entry
  include SS::Document
  include SS::Reference::Site

  field :email, type: String, metadata: { from: :email }
  field :email_type, type: String
  field :entry_type, type: String
  field :verification_token, type: String

  belongs_to :node, class_name: "Cms::Node"

  validates :email, presence: true, email: true
  validates :email_type, inclusion: { in: %w(text html) }
  validates :entry_type, inclusion: { in: %w(add update delete) }

  public
    def email_type_options
      [%w(テキスト版 text), %w(HTML版 html)]
    end
end
