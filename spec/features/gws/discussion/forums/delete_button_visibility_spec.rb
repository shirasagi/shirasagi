require 'spec_helper'

describe "gws_discussion_forums", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:forum) { create :gws_discussion_forum }
  let(:readable_path) { gws_discussion_forums_path(mode: '-', site: site) }
  let(:editable_path) { gws_discussion_forums_path(mode: 'editable', site: site) }

  before { login_gws_user }

  it "閲覧一覧(readable)では削除ボタン・新規作成・チェックボックスを表示しない" do
    visit readable_path
    expect(current_path).not_to eq sns_login_path
    expect(page).to have_css(".list-item", text: forum.name)
    expect(page).to have_no_css(".soft-delete-all")
    within ".nav-menu" do
      expect(page).to have_no_link I18n.t("ss.links.new")
    end
    expect(page).to have_no_css(".list-items .list-item label.check")
  end

  it "管理一覧(editable)では削除ボタン・新規作成・チェックボックスを表示する" do
    visit editable_path
    expect(current_path).not_to eq sns_login_path
    expect(page).to have_css(".list-item", text: forum.name)
    expect(page).to have_css(".soft-delete-all")
    within ".nav-menu" do
      expect(page).to have_link I18n.t("ss.links.new")
    end
    expect(page).to have_css(".list-items .list-item label.check")
  end
end
