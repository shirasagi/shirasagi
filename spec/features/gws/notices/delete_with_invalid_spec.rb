require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:folder) { create(:gws_notice_folder, cur_site: site) }
  let!(:files) do
    # 1 ファイル 548K のファイルを 4 つ。1MB を確実に超えるようにする
    Array.new(4) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif", user: user) }
  end
  let!(:item) do
    create(
      :gws_notice_post, cur_site: site, cur_user: user, folder: folder, file_ids: files.pluck(:id), state: "closed"
    )
  end

  context "when a post exceeds the total file size limit" do
    before do
      # 制限を 1MB に設定し、添付ファイル容量のエラーが発生するようにする
      folder.update!(notice_total_file_size_limit: 1_024 * 1_024)

      # 添付ファイル容量のエラーが発生することを確認
      Gws::Notice::Post.find(item.id).tap do |after_limitation_shrunk|
        expect(after_limitation_shrunk).to be_invalid
      end
    end

    it do
      # soft delete
      login_user user, to: gws_notice_editables_path(site: site, folder_id: '-', category_id: '-')
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      Gws::Notice::Post.find(item.id).tap do |after_deleted|
        expect(after_deleted.deleted.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
      end

      # hard delete
      within ".current-navi" do
        click_on I18n.t('ss.navi.trash')
      end
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { Gws::Notice::Post.find(item.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "when a folder of post is destroyed" do
    before do
      folder.destroy!
      item.unset(:folder_id)

      # フォルダーエラーが発生することを確認
      Gws::Notice::Post.find(item.id).tap do |after_limitation_shrunk|
        expect(after_limitation_shrunk).to be_invalid
      end
    end

    it do
      # soft delete
      login_user user, to: gws_notice_editables_path(site: site, folder_id: '-', category_id: '-')
      click_on item.name
      click_on I18n.t("ss.links.delete")
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      Gws::Notice::Post.find(item.id).tap do |after_deleted|
        expect(after_deleted.deleted.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
      end

      # hard delete
      within ".current-navi" do
        click_on I18n.t('ss.navi.trash')
      end
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { Gws::Notice::Post.find(item.id) }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
