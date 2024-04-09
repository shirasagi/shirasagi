require 'spec_helper'

describe "translate/public_filter", type: :feature, dbscope: :example, js: true, translate: true do
  let(:site) { cms_site }

  let!(:lang_ja) { create :translate_lang_ja }
  let!(:lang_en) { create :translate_lang_en }
  let(:text) { unique_id }

  let(:page_html) do
    html = []
    html << "<h2>#{text}</h2>"
    html.join("\n")
  end

  let(:layout) { create_cms_layout part }
  let(:node) { create :article_node_page, cur_site: site, layout_id: layout.id }
  let(:item) { create :article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: page_html }
  let!(:part) { create :translate_part_tool, cur_site: site, filename: "tool", ajax_view: "enabled" }

  context "with google" do
    before do
      @net_connect_allowed = WebMock.net_connect_allowed?
      WebMock.disable_net_connect!(allow_localhost: true)
      WebMock.reset!

      install_google_stubs

      site.translate_state = "enabled"
      site.translate_source = lang_ja
      site.translate_target_ids = [lang_en.id]

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

    context "usual case" do
      it do
        visit item.full_url
        select lang_en.name, from: "translate-tool-1"
        wait_for_ajax
        expect(page).to have_css("article.body", text: "[en:#{text}]")

        # access with no referer
        visit current_path
        wait_for_ajax
        expect(page).to have_css("article.body", text: "[en:#{text}]")
      end
    end

    context "deny no referer" do
      before do
        site.translate_referer_restriction = "enabled"
        site.update!
      end

      it do
        visit item.full_url
        select lang_en.name, from: "translate-tool-1"
        wait_for_ajax
        expect(page).to have_css("article.body", text: "[en:#{text}]")

        # access with no referer
        visit current_path
        expect(page).to have_no_css("article.body", text: "[en:#{text}]")
      end
    end
  end
end
