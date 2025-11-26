require 'spec_helper'

describe Gws::User, type: :model, dbscope: :example do
  let(:site) { gws_site }

  context "#set_gws_main_group_order" do
    let!(:order1) { 10 }
    let!(:order2) { 20 }
    let!(:order3) { 30 }
    let!(:order4) { 40 }
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: order1 }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", order: order2 }
    let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}", order: order3 }

    let(:user1) { create :gws_user, group_ids: [group1.id] }
    let(:user2) { create :gws_user, group_ids: [group2.id] }
    let(:user3) { create :gws_user, group_ids: [group1.id, group2.id, group3.id], in_gws_main_group_id: group3.id }

    it do
      user1
      user2
      user3

      expect(user1.gws_main_group(site).id).to eq group1.id
      expect(user2.gws_main_group(site).id).to eq group2.id
      expect(user3.gws_main_group(site).id).to eq group3.id

      # コールバックにより、ユーザー登録時には main_group の order がセットされる
      expect(user1.gws_main_group_orders[site.id.to_s]).to eq order1
      expect(user2.gws_main_group_orders[site.id.to_s]).to eq order2
      expect(user3.gws_main_group_orders[site.id.to_s]).to eq order3

      # グループ側を更新した時点では変わらない
      group3.order = order4
      group3.update!

      user1.reload
      user2.reload
      user3.reload

      expect(user1.gws_main_group_orders[site.id.to_s]).to eq order1
      expect(user2.gws_main_group_orders[site.id.to_s]).to eq order2
      expect(user3.gws_main_group_orders[site.id.to_s]).to eq order3

      # 定期で呼び出される Gws::UserMainGroupOrderUpdateJob が実行されると更新される
      Gws::UserMainGroupOrderUpdateJob.bind(site_id: site.id).perform_now

      user1.reload
      user2.reload
      user3.reload

      expect(user1.gws_main_group_orders[site.id.to_s]).to eq order1
      expect(user2.gws_main_group_orders[site.id.to_s]).to eq order2
      expect(user3.gws_main_group_orders[site.id.to_s]).to eq order4
    end
  end

  context "#order_by_title" do
    # 役職(降順) > 所属(昇順) > 職員番号 > uid > id
    let!(:title1) { create :gws_user_title, order: 10 }
    let!(:title2) { create :gws_user_title, order: 20 }

    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10 }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 20 }

    let!(:organization_uid1) { "100" }
    let!(:organization_uid2) { "9999" }
    let!(:organization_uid3) { "1" }
    let!(:organization_uid4) { "101" }
    let!(:organization_uid5) { "99" }
    let!(:organization_uid6) { "102" }
    let!(:organization_uid7) { "5" }
    let!(:organization_uid8) { "6" }

    let(:user_t1_g1_u1) do
      create :gws_user, organization_id: site.id, in_title_id: title1.id, group_ids: [group1.id],
organization_uid: organization_uid1
    end
    let(:user_t1_g1_u2) do
      create :gws_user, organization_id: site.id, in_title_id: title1.id, group_ids: [group1.id],
organization_uid: organization_uid2
    end
    let(:user_t1_g2_u3) do
      create :gws_user, organization_id: site.id, in_title_id: title1.id, group_ids: [group2.id],
organization_uid: organization_uid3
    end
    let(:user_t1_g2_u4) do
      create :gws_user, organization_id: site.id, in_title_id: title1.id, group_ids: [group2.id],
organization_uid: organization_uid4
    end
    let(:user_t2_g1_u5) do
      create :gws_user, organization_id: site.id, in_title_id: title2.id, group_ids: [group1.id],
organization_uid: organization_uid5
    end
    let(:user_t2_g1_u6) do
      create :gws_user, organization_id: site.id, in_title_id: title2.id, group_ids: [group1.id],
organization_uid: organization_uid6
    end
    let(:user_t2_g2_u7) do
      create :gws_user, organization_id: site.id, in_title_id: title2.id, group_ids: [group2.id],
organization_uid: organization_uid7
    end
    let(:user_t2_g2_u8) do
      create :gws_user, organization_id: site.id, in_title_id: title2.id, group_ids: [group2.id],
organization_uid: organization_uid8
    end

    it "sorts users by title order, main group order, organization uid, uid, and id" do
      # ユーザーを作成
      user_t2_g2_u8  # title2(20), group2(20), organization_uid: "6" (6)
      user_t2_g2_u7  # title2(20), group2(20), organization_uid: "5" (5)
      user_t2_g1_u6  # title2(20), group1(10), organization_uid: "102" (102)
      user_t2_g1_u5  # title2(20), group1(10), organization_uid: "99" (99)
      user_t1_g2_u4  # title1(10), group2(20), organization_uid: "101" (101)
      user_t1_g2_u3  # title1(10), group2(20), organization_uid: "1" (1)
      user_t1_g1_u2  # title1(10), group1(10), organization_uid: "9999" (9999)
      user_t1_g1_u1  # title1(10), group1(10), organization_uid: "100" (100)

      # order_by_titleスコープでソートされたユーザーの期待値
      expected_users = [
        user_t2_g1_u5,  # organization_uid: "99" (99)
        user_t2_g1_u6,  # organization_uid: "102" (102)
        user_t2_g2_u7,  # organization_uid: "5" (5)
        user_t2_g2_u8,  # organization_uid: "6" (6)
        user_t1_g1_u1,  # organization_uid: "100" (100)
        user_t1_g1_u2,  # organization_uid: "9999" (9999)
        user_t1_g2_u3,  # organization_uid: "1" (1)
        user_t1_g2_u4   # organization_uid: "101" (101)
      ]

      sorted_users = Gws::User.site(site).in(id: expected_users.map(&:id)).order_by_title(site)

      expect(sorted_users.map(&:id)).to eq expected_users.map(&:id)
    end

    it "handles users without titles correctly" do
      # 役職なしのユーザーを作成
      user_no_title = create :gws_user, organization_id: site.id, group_ids: [group1.id], organization_uid: "200"

      # 役職ありのユーザーと混在させてソート
      user_t1_g1_u1
      user_no_title

      sorted_users = Gws::User.site(site).order_by_title(site)

      # 役職なしのユーザーは最後に来ることを確認
      expect(sorted_users.last.id).to eq user_no_title.id
    end

    it "handles users with same title order but different group orders" do
      # 同じ役職orderを持つユーザーを作成
      title_same = create :gws_user_title, order: 15
      group_low = create :gws_group, name: "#{site.name}/#{unique_id}", order: 5
      group_high = create :gws_group, name: "#{site.name}/#{unique_id}", order: 25

      user_low_group = create :gws_user, organization_id: site.id, in_title_id: title_same.id, group_ids: [group_low.id],
organization_uid: "300"
      user_high_group = create :gws_user, organization_id: site.id, in_title_id: title_same.id, group_ids: [group_high.id],
organization_uid: "301"

      sorted_users = Gws::User.site(site).order_by_title(site)

      # グループorderが低い（5）ユーザーが先に来ることを確認
      low_group_index = sorted_users.find_index { |u| u.id == user_low_group.id }
      high_group_index = sorted_users.find_index { |u| u.id == user_high_group.id }

      expect(low_group_index).to be < high_group_index
    end

    it "handles users with same title and group orders but different organization uids" do
      # 同じ役職・グループorderを持つユーザーを作成
      title_same = create :gws_user_title, order: 15
      group_same = create :gws_group, name: "#{site.name}/#{unique_id}", order: 15

      user_uid_100 = create :gws_user, organization_id: site.id, in_title_id: title_same.id, group_ids: [group_same.id],
organization_uid: "100"
      user_uid_200 = create :gws_user, organization_id: site.id, in_title_id: title_same.id, group_ids: [group_same.id],
organization_uid: "200"

      sorted_users = Gws::User.site(site).order_by_title(site)

      # organization_uidが小さい（100）ユーザーが先に来ることを確認
      uid_100_index = sorted_users.find_index { |u| u.id == user_uid_100.id }
      uid_200_index = sorted_users.find_index { |u| u.id == user_uid_200.id }

      expect(uid_100_index).to be < uid_200_index
    end

    it "handles users with empty organization uid" do
      # organization_uidが空のユーザーを作成
      user_empty_uid = create :gws_user, organization_id: site.id, in_title_id: title1.id, group_ids: [group1.id],
organization_uid: ""
      user_with_uid = create :gws_user, organization_id: site.id, in_title_id: title1.id, group_ids: [group1.id],
organization_uid: "100"

      sorted_users = Gws::User.site(site).order_by_title(site)

      # organization_uidが空のユーザーが先に来ることを確認（空文字列は他の文字列より小さい）
      empty_uid_index = sorted_users.find_index { |u| u.id == user_empty_uid.id }
      with_uid_index = sorted_users.find_index { |u| u.id == user_with_uid.id }

      expect(empty_uid_index).to be < with_uid_index
    end

    it "falls back to uid and id when higher priority keys are identical" do
      # すべての優先キーが同一になった場合に uid → id の順で比較されることを検証
      title_same = create :gws_user_title, order: 15
      group_same = create :gws_group, name: "#{site.name}/#{unique_id}", order: 15

      user_uid_nil1 = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: nil, uid: nil, email: "tie-#{unique_id}@example.jp"
      user_uid_nil2 = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: nil, uid: nil, email: "tie-#{unique_id}@example.jp"
      user_uid_alpha = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: nil, uid: "alpha"
      user_uid_beta = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: nil, uid: "beta"

      target_ids = [
        user_uid_nil1.id,
        user_uid_nil2.id,
        user_uid_alpha.id,
        user_uid_beta.id
      ]

      sorted_users = Gws::User.site(site).in(id: target_ids).order_by_title(site)

      alpha_index = sorted_users.find_index { |u| u.id == user_uid_alpha.id }
      beta_index = sorted_users.find_index { |u| u.id == user_uid_beta.id }
      expect(alpha_index).to be < beta_index

      nil1_index = sorted_users.find_index { |u| u.id == user_uid_nil1.id }
      nil2_index = sorted_users.find_index { |u| u.id == user_uid_nil2.id }
      expect(nil1_index).to be < nil2_index
    end

    it "sorts users by organization_uid_numeric in numeric order, not string order" do
      # 職員番号が数値として正しくソートされることを確認
      # 文字列比較では "10081" < "5880" となるが、数値比較では 5880 < 10081 となる
      title_same = create :gws_user_title, order: 15
      group_same = create :gws_group, name: "#{site.name}/#{unique_id}", order: 15

      user_5880 = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: "5880"
      user_8885 = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: "8885"
      user_10081 = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: "10081"
      user_10143 = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: "10143"
      user_10144 = create :gws_user, organization_id: site.id, in_title_id: title_same.id,
        group_ids: [group_same.id], organization_uid: "10144"

      # organization_uid_numericが自動設定されていることを確認
      expect(user_5880.reload.organization_uid_numeric).to eq 5880
      expect(user_8885.reload.organization_uid_numeric).to eq 8885
      expect(user_10081.reload.organization_uid_numeric).to eq 10_081
      expect(user_10143.reload.organization_uid_numeric).to eq 10_143
      expect(user_10144.reload.organization_uid_numeric).to eq 10_144

      # ソートが正しく機能することを確認するため、IDの順番をランダムにする
      target_ids = [
        user_5880.id,
        user_8885.id,
        user_10081.id,
        user_10143.id,
        user_10144.id
      ].shuffle

      Rails.logger.debug do
        "[Gws::UserSpec#sorts users by organization_uid_numeric in numeric order, not string order] target_ids: #{target_ids.inspect}"
      end

      sorted_users = Gws::User.site(site).in(id: target_ids).order_by_title(site)

      # 数値順でソートされていることを確認（5880 < 8885 < 10081 < 10143 < 10144）
      sorted_ids = sorted_users.map(&:id)
      expect(sorted_ids).to eq [
        user_5880.id,
        user_8885.id,
        user_10081.id,
        user_10143.id,
        user_10144.id
      ]
    end

    it "updates organization_uid_numeric when organization_uid changes" do
      user = create :gws_user, organization_id: site.id, organization_uid: "100"
      expect(user.organization_uid_numeric).to eq 100

      user.organization_uid = "200"
      user.save
      expect(user.reload.organization_uid_numeric).to eq 200
    end

    it "sets organization_uid_numeric to nil when organization_uid is blank" do
      user = create :gws_user, organization_id: site.id, organization_uid: "100"
      expect(user.organization_uid_numeric).to eq 100

      user.organization_uid = nil
      user.save
      expect(user.reload.organization_uid_numeric).to be_nil
    end

    it "handles non-numeric organization_uid by converting to nil" do
      # 数値に変換できない職員番号の場合、nilに変換される
      user = create :gws_user, organization_id: site.id, organization_uid: "abc"
      expect(user.organization_uid_numeric).to be_nil
    end
  end

  context "#gws_main_group" do
    # メイングループの取得機能をテスト
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10 }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 20 }

    it "returns the first group when no main group is explicitly set" do
      # メイングループが明示的に設定されていない場合
      user = create :gws_user, group_ids: [group1.id, group2.id]

      expect(user.gws_main_group(site).id).to eq group1.id
    end

    it "returns the explicitly set main group" do
      # メイングループが明示的に設定されている場合
      user = create :gws_user, group_ids: [group1.id, group2.id], in_gws_main_group_id: group2.id

      expect(user.gws_main_group(site).id).to eq group2.id
    end

    it "returns nil when user has no groups" do
      # グループに所属していないユーザー（バリデーションをスキップして作成）
      user = build :gws_user, group_ids: []
      user.save(validate: false)

      expect(user.gws_main_group(site)).to be_nil
    end
  end

  context "#gws_default_group" do
    # デフォルトグループの取得機能をテスト
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10 }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 20 }

    it "returns the explicitly set default group" do
      # デフォルトグループが明示的に設定されている場合
      user = create :gws_user, group_ids: [group1.id, group2.id], in_gws_default_group_id: group2.id

      expect(user.gws_default_group(site).id).to eq group2.id
    end

    it "falls back to main group when no default group is set" do
      # デフォルトグループが設定されていない場合、メイングループにフォールバック
      user = create :gws_user, group_ids: [group1.id, group2.id], in_gws_main_group_id: group1.id

      expect(user.gws_default_group(site).id).to eq group1.id
    end

    it "returns nil when user has no groups" do
      # グループに所属していないユーザー（バリデーションをスキップして作成）
      user = build :gws_user, group_ids: []
      user.save(validate: false)

      expect(user.gws_default_group(site)).to be_nil
    end
  end

  context "#set_gws_default_group_id" do
    # デフォルトグループIDの設定機能をテスト
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10 }

    it "sets the default group id for the current site" do
      user = create :gws_user, group_ids: [group1.id]
      user.cur_site = site

      user.set_gws_default_group_id(group1.id)

      expect(user.gws_default_group_ids[site.id.to_s]).to eq group1.id
    end

    it "removes the default group id when nil is passed" do
      user = create :gws_user, group_ids: [group1.id]
      user.cur_site = site
      user.gws_default_group_ids = { site.id.to_s => group1.id }

      user.set_gws_default_group_id(nil)

      expect(user.gws_default_group_ids[site.id.to_s]).to be_nil
    end

    it "handles non-numeric group id" do
      user = create :gws_user, group_ids: [group1.id]
      user.cur_site = site

      user.set_gws_default_group_id("invalid")

      expect(user.gws_default_group_ids[site.id.to_s]).to be_nil
    end
  end

  context "validation" do
    # バリデーション機能をテスト
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10 }

    it "validates presence of groups" do
      # グループが設定されていないユーザーは無効
      user = build :gws_user, group_ids: []

      expect(user).not_to be_valid
      expect(user.errors[:group_ids]).to include(I18n.t("errors.messages.blank"))
    end

    it "validates gws_main_group belongs to user's groups" do
      # ユーザーが所属していないグループをメイングループに設定することは無効
      other_group = create :gws_group, name: "#{site.name}/#{unique_id}", order: 20
      user = build :gws_user, group_ids: [group1.id], in_gws_main_group_id: other_group.id
      user.cur_site = site

      expect(user).not_to be_valid
      expect(user.errors[:gws_main_group_ids]).to include(I18n.t("errors.messages.invalid"))
    end

    it "validates gws_default_group belongs to user's groups" do
      # ユーザーが所属していないグループをデフォルトグループに設定することは無効
      other_group = create :gws_group, name: "#{site.name}/#{unique_id}", order: 20
      user = build :gws_user, group_ids: [group1.id], in_gws_default_group_id: other_group.id
      user.cur_site = site

      expect(user).not_to be_valid
      expect(user.errors[:gws_default_group_ids]).to include(I18n.t("errors.messages.invalid"))
    end
  end

  context "error handling" do
    # エラーハンドリング機能をテスト
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10 }

    it "handles missing site gracefully in gws_main_group" do
      # サイトが設定されていない場合の処理
      user = create :gws_user, group_ids: [group1.id]

      # siteがnilでも、@cur_siteが設定されていれば最初のグループを返す
      # 実際の実装では、siteがnilの場合は@cur_siteを使用し、それもnilの場合は最初のグループを返す
      result = user.gws_main_group(nil)
      expect(result).to be_present
      expect(result.id).to eq group1.id
    end

    it "handles missing site gracefully in gws_default_group" do
      # サイトが設定されていない場合の処理
      user = create :gws_user, group_ids: [group1.id]

      # siteがnilでも、@cur_siteが設定されていればグループを返す
      result = user.gws_default_group(nil)
      expect(result).to be_present
      expect(result.id).to eq group1.id
    end

    it "handles invalid group ids in set_gws_default_group_id" do
      # 無効なグループIDを設定しようとした場合の処理
      user = create :gws_user, group_ids: [group1.id]
      user.cur_site = site

      expect { user.set_gws_default_group_id("invalid_id") }.not_to raise_error
      expect(user.gws_default_group_ids[site.id.to_s]).to be_nil
    end

    it "handles missing cur_site in set_gws_default_group_id" do
      # cur_siteが設定されていない場合の処理
      user = create :gws_user, group_ids: [group1.id]
      # @cur_siteを明示的にnilに設定
      user.instance_variable_set(:@cur_site, nil)

      # @cur_siteがnilの場合、NoMethodErrorが発生することを確認
      expect { user.set_gws_default_group_id(group1.id) }.to raise_error(NoMethodError, /undefined method `id' for nil:NilClass/)
    end

    it "handles order_by_title with empty user set" do
      # ユーザーが存在しない場合のorder_by_titleの動作
      # 他のテストで作成されたユーザーを除外するため、特定の条件でフィルタリング
      sorted_users = Gws::User.site(site).where(organization_uid: "nonexistent").order_by_title(site)

      expect(sorted_users).to be_empty
    end

    it "handles order_by_title with single user" do
      # ユーザーが1人だけの場合のorder_by_titleの動作
      user = create :gws_user, organization_id: site.id, group_ids: [group1.id], organization_uid: "single_user_test"

      sorted_users = Gws::User.site(site).where(organization_uid: "single_user_test").order_by_title(site)

      expect(sorted_users.length).to eq 1
      expect(sorted_users.first.id).to eq user.id
    end

    it "handles UserMainGroupOrderUpdateJob with non-existent groups" do
      # 存在しないグループのorderを更新しようとした場合の処理
      _user = create :gws_user, group_ids: [group1.id]

      # グループを削除
      group1.destroy

      # ジョブを実行してもエラーが発生しないことを確認
      expect { Gws::UserMainGroupOrderUpdateJob.bind(site_id: site.id).perform_now }.not_to raise_error
    end
  end
end
