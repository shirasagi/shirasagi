require 'spec_helper'

describe "translate/public_filter", type: :feature, dbscope: :example, js: true, translate: true do
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }

  let!(:text1) { unique_id }
  let!(:text2) { unique_id }

  let!(:part1) { create :translate_part_tool, ajax_view: "disabled" }
  let!(:part2) { create :cms_part_free, ajax_view: "disabled", html: "<div class=\"free-part\">#{text1}</div>" }
  let!(:part3) { create :cms_part_free, ajax_view: "enabled", html: "<div class=\"free-part\">#{text2}</div>" }

  let!(:layout) { create_cms_layout part1, part2, part3 }
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
        expect(page).to have_css(".free-part", text: text1)
        expect(page).to have_css(".free-part", text: text2)
      end
    end

    context "en" do
      it do
        visit item.full_url
        expect(page).to have_css("#translate-tool-1", text: I18n.t("translate.views.select_lang"))
        expect(page).to have_css("#translate-tool-1", text: lang_en.name)
        select lang_en.name, from: "translate-tool-1"
        wait_for_ajax

        expect(page).to have_css(".free-part", text: "[en:#{text1}]")
        expect(page).to have_css(".free-part", text: "[en:#{text2}]")
      end
    end
  end
end
