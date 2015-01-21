class Ezine::Entry
  include SS::Document
  include SS::Reference::Site
  include Ezine::Entryable

  validates :email, presence: true, email: true
  validates :email_type, inclusion: { in: %w(text html) }
  validates :entry_type, inclusion: { in: %w(add update delete) }

  before_create ->{ self.verification_token = unique_token },
    if: ->{ SS.config.ezine.deliver_verification_mail_from_here }
  after_create ->{ Ezine::Mailer.verification_mail(self).deliver },
    if: ->{ SS.config.ezine.deliver_verification_mail_from_here }

  class << self
    def pull_from_public!
      begin
        Ezine::PublicEntry.verified.each do |public_entry|
          entry = Ezine::Entry.create! public_entry.attributes
          public_entry.destroy
          entry.accept
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

    # Verify an entry.
    #
    # If current server is primary (for members registration), accept this
    # entry.
    #
    # If this entry has been already verified, do nothing.
    #
    # エントリーの確認をする．
    #
    # もし現アプリケーションがプライマリ(メンバ登録用)であれば
    # エントリーを受理する．
    #
    # 既にこのエントリーが確認済みであれば何もしない．
    def verify
      return if verification_token.nil?
      update verification_token: nil
      accept if SS.config.ezine.register_member_here
    end

    # Accept an entry and create, update or destroy a Ezine::Member.
    #
    # Switch the action with entry_type field.
    #
    # * "add"    -> "create"
    # * "update" -> "update"
    # * "delete" -> "destroy"
    #
    # エントリーを受け付け，Ezine::Member を作成または更新または削除する．
    #
    # entry_type フィールドの値により動作を切り替える.
    #
    # * "add"    -> 作成
    # * "update" -> 更新
    # * "delete" -> 削除
    def accept
      member = Ezine::Member.where(
        site_id: site_id, node_id: node_id, email: email
      ).first
      case entry_type
      when "add"
        return if member.present?
        Ezine::Member.create(
          site_id: site_id,
          node_id: node_id,
          email: email,
          email_type: email_type
        )
      when "update"
        return if member.nil?
        member.update email_type: email_type
      when "delete"
        return if member.nil?
        member.destroy
      end
    end

  private
    def unique_token
      loop do
        t = Digest::SHA1.hexdigest SecureRandom.uuid
        return t if Ezine::Entry.where(verification_token: t).first.nil?
      end
    end
end
