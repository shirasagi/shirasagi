require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:part) { create :cms_part_free, html: '<meta name="foo" content="bar" />' }
  let(:layout_html) do
    html = []
    html << "<html><head>"
    html << "{{ part \"#{part.filename.sub(/\..*/, '')}\" }}"
    html << "</head><body><br><br><br><div id=\"main\" class=\"page\">"
    html << "{{ yield }}"
    html << "</div></body></html>"
    html.join("\n")
  end
  let(:layout) { create :cms_layout, html: layout_html }
  let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }

  before { login_cms_user }

  describe "page preview" do
    context "normal page" do
      let(:text) { unique_id }
      let(:html) { "<p>#{text}</p>" }
      let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: html) }

      it do
        visit cms_preview_path(site: site, path: item.preview_path)

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
      end
    end

    context "formed page" do
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
      let!(:column1) { create(:cms_column_text_field, cur_form: form, order: 1, input_type: 'text') }
      let!(:item) do
        create(
          :article_page, cur_site: site, cur_node: node, layout_id: layout.id, form: form,
          column_values: [
            column1.value_type.new(column: column1, value: unique_id * 2)
          ]
        )
      end
      let(:column_value1) { item.column_values[0] }

      before do
        node.st_form_ids = [ form.id ]
        node.save!

        form.html = "<p>{{ values['#{column1.name}'] }}</p>"
        form.save!
      end

      it do
        visit cms_preview_path(site: site, path: item.preview_path)

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
          expect(page).to have_css("#ss-preview-form-start[data-form-id='#{form.id}']", visible: false)
          selector = ".ss-preview-column[data-page-id='#{item.id}'][data-column-id='#{column_value1.id}']"
          expect(page).to have_css(selector, text: column_value1.value)
        end
      end
    end

    context "with login and closed page" do
      let(:text) { unique_id }
      let(:html) { "<p>#{text}</p>" }
      let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: html, state: 'closed') }

      it do
        visit sns_mypage_path
        within ".user-navigation" do
          wait_for_event_fired("turbo:frame-load") { click_on cms_user.name }
          within "#user-main-dropdown" do
            click_link I18n.t('ss.logout')
          end
        end

        visit cms_preview_path(site: site, path: item.preview_path)
        within "form" do
          fill_in "item[email]", with: Cms::User.first.email
          fill_in "item[password]", with: "pass"
          click_on I18n.t('ss.login')
        end

        within "#ss-preview" do
          within ".ss-preview-wrap-column-edit-mode" do
            expect(page).to have_button(I18n.t("cms.inplace_edit"))
            expect(page).to have_button(I18n.t("ss.buttons.new"))
            expect(page).to have_link(I18n.t("cms.draft_page"))
            expect(page).to have_button(I18n.t("workflow.buttons.approve"))
            expect(page).to have_button(I18n.t("ss.buttons.publish"))
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

        page.accept_confirm do
          click_button I18n.t('ss.buttons.publish')
        end

        wait_for_js_ready
        expect(page).to have_css('div.ss-preview-notice-wrap', text: I18n.t('ss.notice.published'))

        within "#ss-preview" do
          within ".ss-preview-wrap-column-edit-mode" do
            expect(page).to have_button(I18n.t("cms.inplace_edit"))
            expect(page).to have_button(I18n.t("ss.buttons.new"))
            expect(page).to have_link(I18n.t("cms.draft_page"))
            expect(page).to have_no_button(I18n.t("workflow.buttons.approve"))
            expect(page).to have_no_button(I18n.t("ss.buttons.publish"))
          end
          within ".ss-preview-wrap-column-mode-change" do
            expect(page).to have_button(I18n.t("ss.links.pc"))
            expect(page).to have_button(I18n.t("ss.links.mobile"))
            expect(page).to have_button(I18n.t("cms.layout"))
            expect(page).to have_button(I18n.t("ss.links.back_to_administration"))
          end
        end
      end
    end

    context "check accessibility tools" do
      let(:accessibilty_tool) { create(:accessibilty_tool, cur_site: site) }
      let(:layout_html) do
        html = []
        html << "<html><head>"
        html << "{{ part \"#{accessibilty_tool.filename.sub(/\..*/, '')}\" }}"
        html << "{{ part \"#{accessibilty_tool.filename.sub(/\..*/, '')}\" }}"
        html << "<script src='/assets/cms/public.js'></script>"
        html << "</head><body><br><br><br><div id=\"main\" class=\"page\">"
        html << "{{ yield }}"
        html << "</div></body></html>"
        html.join("\n")
      end
      let(:layout) { create :cms_layout, html: layout_html }
      let(:text) { unique_id }
      let(:html) { "<p>#{text}</p>" }
      let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: html) }
      it "check if accessibility tools are clickable if multiple time" do
        visit cms_preview_path(site: site, path: item.preview_path)
        ['ss-kana', 'ss-voice'].each do |tool|
          divs = page.all("div[data-tool='#{tool}']")
          divs.each do |div|
            if tool == 'ss-kana'
              links = div.all('a')
              links.each do |link|
                expect(link).to be_visible
              end
            elsif tool == 'ss-voice'
              links = div.all('a')
              links.each do |link|
                expect(link[:href]).to include('voice')
              end
            end
          end
        end
        spans = page.all("span[data-tool='ss-theme']")
        spans.each do |span|
          links = span.all('a')
          links.each do |link|
            expect(link).to be_visible
          end
        end

        divs = page.all("div[id=size]")
        divs.each do |div|
          links = div.all('a', visible: true)
          links.each do |link|
            expect(link).to be_visible
          end
        end
      end
    end
  end

  describe "node preview" do
    let(:text) { unique_id }
    let(:html) { "<p>#{text}</p>" }
    let!(:item1) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: html) }

    let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_text_field, cur_form: form, order: 1, input_type: 'text') }
    let!(:item2) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, form: form,
        column_values: [
          column1.value_type.new(column: column1, value: unique_id * 2)
        ]
      )
    end
    let(:column_value1) { item2.column_values[0] }

    before do
      node.st_form_ids = [ form.id ]
      node.save!

      form.html = "<p>{{ values['#{column1.name}'] }}</p>"
      form.save!
    end

    context "when loop_html is given" do
      before do
        node.loop_html = "<div data-id=\"\#{id}\">\#{html}</div>"
        node.save!
      end

      it do
        visit cms_preview_path(site: site, path: node.preview_path)

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
          expect(page).to have_no_css(".ss-preview-page")
          expect(page).to have_no_css(".ss-preview-column")
          expect(page).to have_css("div[data-id='#{item1.id}']", text: text)
          # expect(page).to have_css("div[data-id='#{item2.id}']", text: "")
          expect(find("div[data-id='#{item2.id}']").text).to eq ""
        end
      end
    end

    context "when loop_liquid is given" do
      before do
        node.loop_format = "liquid"
        node.loop_liquid = "{% for page in pages %}<div data-id=\"{{ page.id }}\">{{ page.html }}</div>{% endfor %}"
        node.save!
      end

      it do
        visit cms_preview_path(site: site, path: node.preview_path)

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
          expect(page).to have_no_css(".ss-preview-page")
          expect(page).to have_no_css(".ss-preview-column")
          expect(page).to have_css("div[data-id='#{item1.id}']", text: text)
          # expect(page).to have_css("div[data-id='#{item2.id}']", text: column_value1.value)
          expect(find("div[data-id='#{item2.id}']").text).to eq column_value1.value
        end
      end
    end
  end
end
