require 'spec_helper'

describe "chat_intents", type: :feature, js: true do
  let(:site) { cms_site }
  let(:first_suggest) { [unique_id] }
  let(:node) { create_once :chat_node_bot, first_suggest: first_suggest }
  let(:suggest) { [unique_id] }
  let!(:item) { create :chat_intent, node_id: node.id, suggest: suggest }
  let(:index_path) { chat_intents_path site.id, node }
  let(:new_path) { new_chat_intent_path site.id, node }
  let(:show_path) { chat_intent_path site.id, node, item }
  let(:edit_path) { edit_chat_intent_path site.id, node, item }
  let(:delete_path) { delete_chat_intent_path site.id, node, item }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_css('td.expandable', count: 4)
      expect(page).to have_css('a', text: I18n.t('chat.links.add_or_edit'), count: 3)
      expect(page).to have_css('td', text: I18n.t('chat.not_found_intent'), count: 2)
      expect(find('td.expandable', text: I18n.t('chat.first_suggest'))).to be_visible
      expect(find('td.expandable', text: first_suggest.first)).not_to be_visible
      expect(find('td.expandable', text: item.name)).to be_visible
      expect(find('td.expandable', text: suggest.first)).not_to be_visible
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[phrase]", with: "sample"
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")
    end

    context 'when phrase is duplicated' do
      let!(:item1) { create :chat_intent, node_id: node.id, phrase: first_suggest }
      let!(:item2) { create :chat_intent, node_id: node.id, phrase: first_suggest }

      it "#index" do
        visit index_path
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_css('td.expandable', count: 5)
        expect(page).to have_css('a', text: I18n.t('chat.links.add_or_edit'), count: 4)
        expect(page).to have_css('td.expandable', text: first_suggest.first, count: 2)
        expect(page).to have_css('td', text: I18n.t('chat.not_found_intent'), count: 1)
        expect(find('td.expandable', text: I18n.t('chat.first_suggest'))).to be_visible
        expect(first('td.expandable', text: first_suggest.first)).not_to be_visible
        expect(find('td.expandable', text: item.name)).to be_visible
        expect(find('td.expandable', text: suggest.first)).not_to be_visible
      end
    end

    context 'when intent is loop' do
      let!(:item1) { create :chat_intent, node_id: node.id, name: "#{item.name}-1", phrase: suggest, suggest: item.phrase }

      it "#index" do
        visit index_path
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_css('td.expandable', count: 5)
        expect(page).to have_css('a', text: I18n.t('chat.links.add_or_edit'), count: 3)
        expect(page).to have_css('td', text: I18n.t('chat.not_found_intent'), count: 1)
        expect(page).to have_css('td', text: I18n.t('chat.loop_intent'), count: 1)
        expect(find('td.expandable', text: I18n.t('chat.first_suggest'))).to be_visible
        expect(find('td.expandable', text: first_suggest.first)).not_to be_visible
        expect(find('td.expandable', text: item.name)).to be_visible
        expect(find('td.expandable', text: suggest.first)).not_to be_visible
        expect(find('td.expandable', text: item.phrase)).not_to be_visible
      end
    end
  end
end
