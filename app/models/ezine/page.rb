class Ezine::Page
  include Cms::Model::Page
  include Cms::Page::SequencedFilename
  include Ezine::Addon::Body
  include Ezine::Addon::DeliverPlan
  include Cms::Addon::Release
  include Cms::Addon::ReleasePlan
  include Cms::Addon::GroupPermission

  field :test_delivered, type: DateTime
  field :completed, type: Boolean, default: false
  embeds_many :results, class_name: "Ezine::Result"

  default_scope ->{ where(route: "ezine/page") }

  # Get members to deliver this page.
  #
  # Return an empty array when a delivery is completed.
  #
  # Return members array not included in sent logs when a delivery is
  # incompleted.
  #
  # このページを配信するべきメンバー一覧を取得する。
  #
  # 配信が完了していれば空の配列が返る。
  #
  # 配信が完了していない場合は配信ログが存在しないメンバー一覧が返る。
  #
  # @return [Array<Ezine::Member>]
  #   Members to deliver.
  #
  #   配信するべきメンバー一覧。
  def members_to_deliver
    return [] if completed
    emails = Ezine::SentLog.where(page_id: id).map(&:email)
    parent_node = parent.becomes_with_route
    parent_node.members_to_deliver.where(email: {"$nin" => emails})
  end

  # Deliver a mail to a member.
  #
  # Create a sent log if it is succeeded and isn't test delivery.
  #
  # 1メンバーにメールを配信する。
  #
  # 成功しかつテスト配信でなければ配信ログを作成する。
  #
  # @param [Ezine::Member, Ezine::TestMember] member
  #
  # @raise [Object]
  #   An error object from `ActionMailer#deliver_now`
  #
  #   `ActionMailer#deliver_now` メソッドからのエラーオブジェクト
  def deliver_to(member)
    Ezine::Mailer.page_mail(self, member).deliver_now
    Ezine::SentLog.create(
      node_id: parent.id, page_id: id, email: member.email
    ) unless member.test_member?
  end

  # Do a test delivery.
  #
  # テスト配信を行う。
  def deliver_to_test_members
    parent_node = parent.becomes_with_route
    parent_node.test_members_to_deliver.each do |test_member|
      deliver_to test_member
    end

    update test_delivered: Time.zone.now
  end
end
