require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:folder) { create(:gws_notice_folder) }
  let!(:item) { create :gws_notice_post, folder: folder, comment_state: "enabled" }

  context "comment crud" do
    let(:comment) { unique_id }
    let(:comment2) { unique_id }

    before { login_gws_user }

    it do
      visit gws_notice_readables_path(site: site, folder_id: '-', category_id: '-')
      click_on item.name

      within "form#comment-form" do
        fill_in "item[text]", with: comment
        click_on I18n.t('gws/schedule.buttons.comment')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      item.reload
      expect(item.comments.count).to eq 1
      item.comments.first.tap do |c|
        expect(c.text).to eq comment
      end

      within "#addon-gws-agents-addons-notice-comment_post .index" do
        click_on I18n.t("ss.buttons.edit")
      end
      within "#ajax-box" do
        within "form#item-form" do
          fill_in "item[text]", with: comment2
          click_on I18n.t('ss.buttons.save')
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      item.reload
      expect(item.comments.count).to eq 1
      item.comments.first.tap do |c|
        expect(c.text).to eq comment2
      end

      within "#addon-gws-agents-addons-notice-comment_post .index" do
        click_on I18n.t("ss.buttons.delete")
      end
      within "#ajax-box" do
        within "form" do
          click_on I18n.t('ss.buttons.delete')
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      item.reload
      expect(item.comments.count).to eq 0
    end
  end
end
