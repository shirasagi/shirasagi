class Ezine::Entry
  include SS::Document
  include SS::Reference::Site
  include Ezine::Entryable

  validates :email, presence: true, email: true
  validates :email_type, inclusion: { in: %w(text html) }
  validates :entry_type, inclusion: { in: %w(add update delete) }

  public
    def email_type_options
      [%w(テキスト版 text), %w(HTML版 html)]
    end
end
