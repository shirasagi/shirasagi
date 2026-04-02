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
    # ソート順: 役職order(降順) > 所属order(昇順) > 職員番号タイプ > 職員番号ソートキー(昇順) > uid(昇順) > id(昇順)

    context "職員番号のソートキー生成" do
      it "数字のみ → numeric型、10桁ゼロ埋め" do
        user = create :gws_user, organization_id: site.id, organization_uid: "5880"
        expect(user.organization_uid_type).to eq 'numeric'
        expect(user.organization_uid_sort_key).to eq '0000005880'
      end

      it "アルファベット+数字 → alpha型、数字部分のみ10桁ゼロ埋め" do
        user = create :gws_user, organization_id: site.id, organization_uid: "KB005"
        expect(user.organization_uid_type).to eq 'alpha'
        expect(user.organization_uid_sort_key).to eq 'KB0000000005'
      end

      it "職員番号を変更するとソートキーも更新される" do
        user = create :gws_user, organization_id: site.id, organization_uid: "100"
        expect(user.organization_uid_type).to eq 'numeric'
        expect(user.organization_uid_sort_key).to eq '0000000100'

        user.organization_uid = "A200"
        user.save!
        user.reload
        expect(user.organization_uid_type).to eq 'alpha'
        expect(user.organization_uid_sort_key).to eq 'A0000000200'
      end

      it "職員番号が空になるとソートキーもnilになる" do
        user = create :gws_user, organization_id: site.id, organization_uid: "100"
        user.organization_uid = nil
        user.save!
        user.reload
        expect(user.organization_uid_type).to be_nil
        expect(user.organization_uid_sort_key).to be_nil
      end

      it "アンダースコアやハイフンはソートキーに保持される" do
        user_with_underscore = create :gws_user, organization_id: site.id, organization_uid: "user_001"
        user_without = create :gws_user, organization_id: site.id, organization_uid: "user001"
        expect(user_with_underscore.organization_uid_sort_key).to eq 'user_0000000001'
        expect(user_without.organization_uid_sort_key).to eq 'user0000000001'
      end
    end

    context "数字のみの職員番号の並び順" do
      let!(:title1) { create :gws_user_title, order: 15 }
      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 15 }

      def create_users(*uids)
        uids.map do |uid|
          create :gws_user, organization_id: site.id, in_title_id: title1.id,
            group_ids: [group1.id], organization_uid: uid
        end
      end

      def sorted_uids(users)
        ids = users.map(&:id).shuffle
        Gws::User.site(site).in(id: ids).order_by_title(site).map(&:organization_uid)
      end

      it "文字列順ではなく数値として小さい順に並ぶ" do
        # 文字列比較では "10081" < "5880" だが、数値として正しく並ぶ
        users = create_users("10081", "5880", "10144", "8885", "10143")

        expect(sorted_uids(users)).to eq %w[5880 8885 10081 10143 10144]
      end

      it "西暦+連番形式も数値として小さい順に並ぶ" do
        # 2024年の職員が先、2025年の職員が後
        users = create_users("2025001", "2024002", "2025999", "2024001", "2024100")

        expect(sorted_uids(users)).to eq %w[2024001 2024002 2024100 2025001 2025999]
      end
    end

    context "アルファベット混在の職員番号の並び順" do
      let!(:title1) { create :gws_user_title, order: 15 }
      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 15 }

      def create_users(*uids)
        uids.map do |uid|
          create :gws_user, organization_id: site.id, in_title_id: title1.id,
            group_ids: [group1.id], organization_uid: uid
        end
      end

      def sorted_uids(users)
        ids = users.map(&:id).shuffle
        Gws::User.site(site).in(id: ids).order_by_title(site).map(&:organization_uid)
      end

      it "同じプレフィックスの場合、数値部分が小さい順に並ぶ" do
        # A200 < A300 < A499（Aグループ内で数値昇順）、B100 < B400（Bグループ内で数値昇順）
        users = create_users("A499", "B400", "A200", "B100", "A300")

        expect(sorted_uids(users)).to eq %w[A200 A300 A499 B100 B400]
      end

      it "異なるプレフィックスはアルファベット順、同じプレフィックス内は数値順に並ぶ" do
        # A < KB のアルファベット順。A200が A1234 より先（数値: 200 < 1234）
        users = create_users("KB005", "A1234", "A200")

        expect(sorted_uids(users)).to eq %w[A200 A1234 KB005]
      end
    end

    context "alpha型とnumeric型が混在する場合の並び順" do
      let!(:title1) { create :gws_user_title, order: 15 }
      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 15 }

      def create_users(*uids)
        uids.map do |uid|
          create :gws_user, organization_id: site.id, in_title_id: title1.id,
            group_ids: [group1.id], organization_uid: uid
        end
      end

      def sorted_uids(users)
        ids = users.map(&:id).shuffle
        Gws::User.site(site).in(id: ids).order_by_title(site).map(&:organization_uid)
      end

      it "alpha_first設定: アルファベット混在が先、数字のみが後に並ぶ" do
        site.organization_uid_sort_order = 'alpha_first'
        site.save!

        users = create_users("A200", "A300", "B100", "50", "500", "1000")

        # alpha型（A200, A300, B100）が先、各グループ内は小さい順
        # numeric型（50, 500, 1000）が後、小さい順
        expect(sorted_uids(users)).to eq %w[A200 A300 B100 50 500 1000]
      end

      it "numeric_first設定: 数字のみが先、アルファベット混在が後に並ぶ" do
        site.organization_uid_sort_order = 'numeric_first'
        site.save!

        users = create_users("A200", "A300", "B100", "50", "500", "1000")

        # numeric型（50, 500, 1000）が先、小さい順
        # alpha型（A200, A300, B100）が後、各グループ内は小さい順
        expect(sorted_uids(users)).to eq %w[50 500 1000 A200 A300 B100]
      end
    end

    context "全ソート優先度の複合テスト" do
      it "役職 > 所属 > 職員番号タイプ > ソートキー > uid > id の順に並ぶ" do
        site.organization_uid_sort_order = 'alpha_first'
        site.save!

        title_high = create :gws_user_title, order: 20
        title_low = create :gws_user_title, order: 10
        group_a = create :gws_group, name: "#{site.name}/group-a", order: 10
        group_b = create :gws_group, name: "#{site.name}/group-b", order: 20

        # 各ソート優先度で結果が分かれるようにデータを作成
        users = []

        # title_high + group_a: alpha型
        users << create(:gws_user, organization_id: site.id, in_title_id: title_high.id,
          group_ids: [group_a.id], organization_uid: "A100")
        users << create(:gws_user, organization_id: site.id, in_title_id: title_high.id,
          group_ids: [group_a.id], organization_uid: "B999")

        # title_high + group_a: numeric型
        users << create(:gws_user, organization_id: site.id, in_title_id: title_high.id,
          group_ids: [group_a.id], organization_uid: "200")
        users << create(:gws_user, organization_id: site.id, in_title_id: title_high.id,
          group_ids: [group_a.id], organization_uid: "500")

        # title_high + group_a: 職員番号なし → uid で分かれる
        users << create(:gws_user, organization_id: site.id, in_title_id: title_high.id,
          group_ids: [group_a.id], organization_uid: nil, uid: "uid-aaa")
        users << create(:gws_user, organization_id: site.id, in_title_id: title_high.id,
          group_ids: [group_a.id], organization_uid: nil, uid: "uid-zzz")

        # title_high + group_b
        users << create(:gws_user, organization_id: site.id, in_title_id: title_high.id,
          group_ids: [group_b.id], organization_uid: "300")

        # title_low + group_a
        users << create(:gws_user, organization_id: site.id, in_title_id: title_low.id,
          group_ids: [group_a.id], organization_uid: "A001")

        target_ids = users.map(&:id).shuffle
        sorted = Gws::User.site(site).in(id: target_ids).order_by_title(site)

        # 各ユーザーを [役職, 所属, 職員番号] のラベルで表示し、並び順を検証
        sorted_labels = sorted.map do |u|
          title_label = u.title_orders&.values&.first == 20 ? "部長" : "課長"
          main_group = u.gws_main_group(site)
          group_label = main_group ? main_group.name.split("/").last : nil
          uid_label = u.organization_uid || "(#{u.uid || 'id'})"
          "#{title_label}/#{group_label}/#{uid_label}"
        end

        expect(sorted_labels).to eq [
          # 1. 役職order降順: 部長(20) が先
          # 2. 所属order昇順: group-a(10) が先
          # 3. 職員番号タイプ: nil < alpha < numeric
          "部長/group-a/(uid-aaa)",  # type=nil, uid昇順
          "部長/group-a/(uid-zzz)",  # type=nil, uid昇順
          "部長/group-a/A100",       # alpha, sort_key昇順
          "部長/group-a/B999",       # alpha, sort_key昇順
          "部長/group-a/200",        # numeric, sort_key昇順
          "部長/group-a/500",        # numeric, sort_key昇順
          # 2. 所属order昇順: group-b(20) が後
          "部長/group-b/300",
          # 1. 役職order降順: 課長(10) が後
          "課長/group-a/A001"
        ]
      end
    end

    context "エッジケース" do
      let!(:title1) { create :gws_user_title, order: 15 }
      let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 15 }

      it "役職なしのユーザーは役職ありのユーザーより後に並ぶ" do
        user_with_title = create :gws_user, organization_id: site.id, in_title_id: title1.id,
          group_ids: [group1.id], organization_uid: "9999"
        user_no_title = create :gws_user, organization_id: site.id,
          group_ids: [group1.id], organization_uid: "1"

        ids = [user_with_title.id, user_no_title.id]
        sorted = Gws::User.site(site).in(id: ids).order_by_title(site)

        # 役職あり(9999)が先、役職なし(1)が後 — 職員番号の大小にかかわらず
        expect(sorted.map(&:organization_uid)).to eq %w[9999 1]
      end

      it "職員番号が未設定のユーザーは職員番号ありのユーザーより先に並ぶ" do
        user_nil = create :gws_user, organization_id: site.id, in_title_id: title1.id,
          group_ids: [group1.id], organization_uid: nil
        user_with = create :gws_user, organization_id: site.id, in_title_id: title1.id,
          group_ids: [group1.id], organization_uid: "100"

        ids = [user_nil.id, user_with.id]
        sorted = Gws::User.site(site).in(id: ids).order_by_title(site)

        expect(sorted.map(&:organization_uid)).to eq [nil, "100"]
      end

      it "職員番号が同じnilの場合、uid昇順 → id昇順でフォールバックする" do
        user_uid_beta = create :gws_user, organization_id: site.id, in_title_id: title1.id,
          group_ids: [group1.id], organization_uid: nil, uid: "beta"
        user_uid_alpha = create :gws_user, organization_id: site.id, in_title_id: title1.id,
          group_ids: [group1.id], organization_uid: nil, uid: "alpha"

        ids = [user_uid_beta.id, user_uid_alpha.id]
        sorted = Gws::User.site(site).in(id: ids).order_by_title(site)

        expect(sorted.map(&:uid)).to eq %w[alpha beta]
      end
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
      expect { user.set_gws_default_group_id(group1.id) }.to raise_error(NoMethodError, /undefined method `id' for nil/)
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
