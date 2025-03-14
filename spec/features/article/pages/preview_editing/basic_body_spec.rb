require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:part) { create :cms_part_free, html: '<div id="part" class="part"><br><br><br>free html part<br><br><br></div>' }
  let(:layout_html) do
    <<~HTML.freeze
      <html>
      <head>
        <meta name="viewport" content="width=device-width,initial-scale=1.0,user-scalable=yes,minimum-scale=1.0,maximum-scale=2.0">
      </head>
      <body>
        <br><br><br>
        {{ part "#{part.filename.sub(/\..*/, '')}" }}
        <div id="main" class="page">
          {{ yield }}
        </div>
      </body>
      </html>
    HTML
  end
  let!(:layout) { create :cms_layout, html: layout_html }
  let!(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }

  before { login_cms_user }

  describe "preview editing" do
    shared_examples "preview editing with basic page" do
      let(:text) { unique_id }
      let(:html) { "<p class=\"page-body\">#{text}</p>" }
      let(:text2) { unique_id }
      let(:html2) { "<p class=\"page-body\">#{text2}</p>" }
      let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: html, state: state) }

      it do
        visit cms_preview_path(site: site, path: item.preview_path)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#ss-preview" do
          within ".ss-preview-wrap-column-edit-mode" do
            expect(page).to have_button(I18n.t("cms.inplace_edit"))
            expect(page).to have_button(I18n.t("ss.buttons.new"))
            expect(page).to have_link(I18n.t("cms.draft_page"))
          end
          within ".ss-preview-wrap-column-mode-change" do
            expect(page).to have_button(I18n.t("ss.links.pc"))
            expect(page).to have_button(I18n.t("ss.links.mobile"))
            expect(page).to have_button(I18n.t("cms.layout"))
            expect(page).to have_button(I18n.t("ss.links.back_to_administration"))
          end
        end

        within "#main" do
          expect(page).to have_no_selector('.ss-preview-part')
          expect(page).to have_css("#ss-preview-content-begin", visible: false)
          expect(page).to have_no_css("#ss-preview-form-start", visible: false)
          expect(page).to have_css(".ss-preview-page[data-page-id='#{item.id}'][data-page-route='article/page']")
          expect(page).to have_css(".ss-preview-page .body", text: text)
        end

        within "#ss-preview" do
          within ".ss-preview-wrap-column-edit-mode" do
            wait_for_event_fired "ss:inplaceModeChanged" do
              click_on I18n.t("cms.inplace_edit")
            end
          end
        end

        first("#main .page-body").click
        within "#ss-preview-overlay" do
          wait_for_event_fired "ss:inplaceEditFrameInitialized" do
            click_on I18n.t("ss.links.edit")
          end
        end

        page.within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            fill_in_ckeditor "item[html]", with: html2

            ss_upload_file "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"

            expect(page).to have_css(".file-view", text: "keyvisual.gif")
            wait_for_ckeditor_event "item[html]", "afterInsertHtml" do
              click_on I18n.t("sns.image_paste")
            end

            click_on button_label
          end
          click_on I18n.t("ss.buttons.ignore_alert")
        end
        expect(page).to have_css(".ss-preview-notice-wrap", text: notice_message)

        item.reload
        expect(item.state).to eq state
        if state == "public"
          expect(item.master?).to be_truthy
          expect(item.branches.count).to eq 1

          branch = item.branches.first
          expect(branch.html).to include(text2)
          expect(branch.files.count).to eq 1
          branch.files.first.tap do |file|
            expect(file.name).to eq "keyvisual.gif"
            expect(file.owner_item_type).to eq branch.class.name
            expect(file.owner_item_id).to eq branch.id

            expect(branch.html).to include(file.url)
          end
        else
          expect(item.html).to include(text2)
          expect(item.files.count).to eq 1

          item.files.first.tap do |file|
            expect(file.name).to eq "keyvisual.gif"
            expect(file.owner_item_type).to eq item.class.name
            expect(file.owner_item_id).to eq item.id

            expect(item.html).to include(file.url)
          end
        end
      end
    end

    context "with public page" do
      let(:state) { "public" }
      let(:button_label) { I18n.t("cms.buttons.save_as_branch") }
      let(:notice_message) { I18n.t("workflow.notice.created_branch_page") }

      it_behaves_like "preview editing with basic page"
    end

    context "with closed page" do
      let(:state) { "closed" }
      let(:button_label) { I18n.t("ss.buttons.save") }
      let(:notice_message) { I18n.t("ss.notice.saved") }

      it_behaves_like "preview editing with basic page"
    end
  end
end
