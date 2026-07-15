require 'spec_helper'

describe "gws_notice_readables", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let!(:item) { create :gws_notice_post, folder: folder, readable_member_ids: [ gws_user.id ] }
  let(:index_path) { gws_notice_readables_path(site: site, folder_id: '-', category_id: '-') }

  before { login_gws_user }

  it "一覧の既読/未読ボタンで選択した項目を一括で既読/未読にできる" do
    expect(item.browsed?(gws_user)).to be_falsey

    visit index_path
    within ".list-head" do
      expect(page).to have_css(".set-browsed-all")
      expect(page).to have_css(".unset-browsed-all")
    end

    # 一括既読
    within ".list-items" do
      first("input[value='#{item.id}']").click
    end
    within ".list-head" do
      page.accept_confirm do
        click_on I18n.t("gws/notice.links.set_seen")
      end
    end
    wait_for_notice I18n.t("ss.notice.set_seen_all")
    expect(item.reload.browsed?(gws_user)).to be_truthy

    # 一括未読
    within ".list-items" do
      first("input[value='#{item.id}']").click
    end
    within ".list-head" do
      page.accept_confirm do
        click_on I18n.t("gws/notice.links.unset_seen")
      end
    end
    wait_for_notice I18n.t("ss.notice.unset_seen_all")
    expect(item.reload.browsed?(gws_user)).to be_falsey
  end
end
