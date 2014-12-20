class Ezine::Entry
  include SS::Document
  include SS::Reference::Site
  include Ezine::Entryable

  validates :email, presence: true, email: true
  validates :email_type, inclusion: { in: %w(text html) }
  validates :entry_type, inclusion: { in: %w(add update delete) }

  class << self
    def pull_from_public!
      begin
        Ezine::PublicEntry.verified.each do |public_entry|
          Ezine::Entry.create! public_entry.attributes
          public_entry.destroy
        end
      rescue
        # TODO Do something to rescue
      end
    end
  end

  public
    def email_type_options
      [%w(テキスト版 text), %w(HTML版 html)]
    end
end
