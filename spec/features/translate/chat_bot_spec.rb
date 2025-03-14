require 'spec_helper'

describe "translate/public_filter", type: :feature, dbscope: :example, js: true, translate: true do
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let!(:part1) { create :translate_part_tool, cur_site: site, ajax_view: "disabled" }

  let!(:suggest1) { "suggest1" }
  let!(:suggest2) { "suggest2" }
  let!(:response1) { "respons1" }
  let!(:response2) { "respons2" }

  let!(:chat_bot_node) { create :chat_node_bot, first_suggest: [suggest1] }
  let!(:site_search_node) { create :cms_node_site_search, cur_site: site }
  let!(:chat_intent1) do
    create(:chat_intent, site_id: site.id, node_id: chat_bot_node.id,
      phrase: [suggest1], suggest: [suggest2], response: response1)
  end
  let!(:chat_intent2) do
    create(:chat_intent, site_id: site.id, node_id: chat_bot_node.id,
      phrase: [suggest2], response: response2, site_search: "enabled")
  end

  let!(:part2) { create :chat_part_bot, cur_node: chat_bot_node }
  let!(:layout) { create_cms_layout part1, part2 }
  let!(:item) { create :cms_page, cur_site: site, filename: "index.html", layout_id: layout.id }

  context "with google" do
    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!(allow_localhost: true)
      WebMock.reset!

      install_google_stubs

      site.translate_state = "enabled"
      site.translate_source = lang_ja
      site.translate_target_ids = [lang_en].map(&:id)

      site.translate_api = "google_translation"
      site.translate_google_api_project_id = "shirasagi-dev"
      "#{Rails.root}/spec/fixtures/translate/gcp_credential.json".tap do |path|
        site.translate_google_api_credential_file = tmp_ss_file(contents: path)
      end

      site.save!

      ::FileUtils.rm_f(item.path)
    end

    after do
      WebMock.reset!
      WebMock.allow_net_connect! if @net_connect_allowed
    end

    context "ja" do
      it do
        visit item.full_url
        within "#chat-1" do
          expect(page).to have_css("a.chat-suggest", text: suggest1)
          click_link suggest1
          wait_for_ajax

          expect(page).to have_text(response1)
          expect(page).to have_css("a.chat-suggest", text: suggest2)
          click_link suggest2
          wait_for_ajax

          expect(page).to have_text(response2)
          search_link = first("a", text: I18n.t("chat.links.open_site_search"))
          expect((search_link["href"]).include?(site.translate_url)).to be_falsey
        end
      end
    end

    context "en" do
      it do
        visit item.full_url
        expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.select_lang"))
        expect(page).to have_css("#translate-tool-1", text: lang_en.name)
        select lang_en.name, from: "translate-tool-1"
        wait_for_ajax

        within "#chat-1" do
          expect(page).to have_css("a.chat-suggest", text: "[en:#{suggest1}]")
          click_link "[en:#{suggest1}]"
          wait_for_ajax

          expect(page).to have_text("[en:#{response1}]")
          expect(page).to have_css("a.chat-suggest", text: "[en:#{suggest2}]")
          click_link "[en:#{suggest2}]"
          wait_for_ajax

          expect(page).to have_text("[en:#{response2}]")
          search_link = first("a", text: "[en:#{I18n.t("chat.links.open_site_search")}]")
          expect((search_link["href"]).include?(site.translate_url)).to be_truthy
        end
      end
    end
  end
end
