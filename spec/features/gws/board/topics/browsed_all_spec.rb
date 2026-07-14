require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_board_category }
  let!(:item) { create :gws_board_topic, category_ids: [ category.id ] }
  let(:readable_path) { gws_board_topics_path site, '-', '-' }
  let(:editable_path) { gws_board_topics_path site, 'editable', '-' }

  before { login_gws_user }

  context "閲覧一覧(readable)" do
    it "削除ボタンを表示せず、既読/未読の一括ボタンを表示する" do
      visit readable_path
      within ".list-head" do
        expect(page).to have_no_css(".soft-delete-all")
        expect(page).to have_css(".set-browsed-all")
        expect(page).to have_css(".unset-browsed-all")
      end
      within ".list-items" do
        expect(page).to have_no_link I18n.t("ss.links.delete")
        # 未読の項目には unread クラスが付く
        expect(page).to have_css(".list-item.unread")
        # メタ情報に既読/未読ラベルを表示する（初期状態は未読）
        expect(page).to have_css(".list-item .meta .seen", text: I18n.t("gws/board.options.browsed_state.unread"))
      end
    end
  end

  context "管理一覧(editable)" do
    it "従来どおり削除ボタンを表示し、既読/未読ボタンは表示しない" do
      visit editable_path
      within ".list-head" do
        expect(page).to have_css(".soft-delete-all")
        expect(page).to have_no_css(".set-browsed-all")
        expect(page).to have_no_css(".unset-browsed-all")
      end
    end
  end

  context "#set_browsed_all / #unset_browsed_all" do
    it "選択した項目を一括で既読/未読にできる" do
      # 既定は未読のみ表示。既読済みも扱うため全て表示で開く
      both_path = "#{readable_path}?s[browsed_state]=both"
      visit both_path
      expect(item.browsed?(gws_user)).to be_falsey

      within ".list-items" do
        first("input[value='#{item.id}']").click
      end
      within ".list-head" do
        page.accept_confirm do
          click_on I18n.t("gws/board.topic.set_browsed")
        end
      end
      wait_for_notice I18n.t("ss.notice.set_seen_all")
      expect(item.reload.browsed?(gws_user)).to be_truthy

      visit both_path
      within ".list-items" do
        expect(page).to have_css(".list-item .meta .seen", text: I18n.t("gws/board.options.browsed_state.read"))
        first("input[value='#{item.id}']").click
      end
      within ".list-head" do
        page.accept_confirm do
          click_on I18n.t("gws/board.topic.unset_browsed")
        end
      end
      wait_for_notice I18n.t("ss.notice.unset_seen_all")
      expect(item.reload.browsed?(gws_user)).to be_falsey

      visit both_path
      within ".list-items" do
        expect(page).to have_css(".list-item .meta .seen", text: I18n.t("gws/board.options.browsed_state.unread"))
      end
    end
  end

  context "未読/全て表示フィルタ" do
    it "既定は全て表示。未読で絞り込むと既読は消える" do
      item.set_browsed!(gws_user)
      visit readable_path
      expect(page).to have_css(".list-item", text: item.name)
      visit "#{readable_path}?s[browsed_state]=unread"
      expect(page).to have_no_css(".list-item")
    end
  end

  context "詳細画面(show)" do
    before do
      # 自動既読タイマーがテスト中に発火しないよう遅延を大きくする
      site.set(board_browsed_delay: 3600)
    end

    it "閲覧一覧経由の詳細は削除ボタンが無く編集ボタンは残る。既読/未読を切り替えられる" do
      expect(item.browsed?(gws_user)).to be_falsey
      visit readable_path
      click_on item.name

      within ".nav-menu" do
        expect(page).to have_no_link I18n.t("ss.links.delete")
        expect(page).to have_link I18n.t("ss.links.edit")
      end

      # 未読 → 「既読にする」を押すと既読になる
      expect(page).to have_link I18n.t("gws/board.topic.set_browsed")
      click_on I18n.t("gws/board.topic.set_browsed")
      wait_for_notice I18n.t("ss.notice.saved")
      expect(item.reload.browsed?(gws_user)).to be_truthy

      # 既読 → ボタンが「未読にする」に変わり、押すと未読に戻る（トグル）
      expect(page).to have_link I18n.t("gws/board.topic.unset_browsed")
      click_on I18n.t("gws/board.topic.unset_browsed")
      wait_for_notice I18n.t("ss.notice.saved")
      expect(item.reload.browsed?(gws_user)).to be_falsey
      expect(page).to have_link I18n.t("gws/board.topic.set_browsed")
    end

    it "管理一覧経由の詳細には削除ボタンがある" do
      visit editable_path
      click_on item.name
      within ".nav-menu" do
        expect(page).to have_link I18n.t("ss.links.delete")
      end
    end
  end
end
