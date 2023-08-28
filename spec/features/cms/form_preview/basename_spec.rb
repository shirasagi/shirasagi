require 'spec_helper'

describe "cms_form_preview", type: :feature, dbscope: :example, js: true do
  before do
    @save_config = SS.config.replace_value_at(:cms, :replace_urls_after_move, true)
  end

  after do
    SS.config.replace_value_at(:cms, :replace_urls_after_move, @save_config)
  end

  context "with article page" do
    let(:site) { cms_site }
    let(:node) { create :article_node_page, cur_site: site }
    let(:node_category_root) { create :category_node_node, cur_site: site }
    let(:node_category_child1) { create :category_node_page, cur_site: site, cur_node: node_category_root }
    let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }
    let(:item) { create(:article_page, cur_site: site, cur_node: node, html: html, category_ids: [ node_category_child1.id ]) }
    let(:edit_path) { edit_article_page_path site.id, node.id, item }

    before { login_cms_user }

    context "pc form preview" do
      it do
        visit edit_path

        within "form#item-form" do
          fill_in "item[name]", with: "sample"
        end

        page.first("#addon-cms-agents-addons-body .preview").click

        switch_to_window(windows.last)
        wait_for_document_loading

        expect(page).to have_css("h2", text: "見出し2")
        expect(page).to have_css("p", text: "内容が入ります。")
        expect(page).to have_css("h3", text: "見出し3")
        expect(page).to have_css("p", text: "内容が入ります。内容が入ります。")
        expect(page).to have_css("header h2", text: "カテゴリー")
      end
    end
  end

  context "with root cms page" do
    let(:site) { cms_site }
    let(:item) { create(:cms_page, filename: "404.html", cur_site: site, html: html) }
    let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }

    let(:edit_path) { edit_cms_page_path site.id, item }

    before { login_cms_user }

    context "pc form preview" do
      it do
        visit edit_path

        within "form#item-form" do
          fill_in "item[name]", with: "sample"
        end

        page.first("#addon-cms-agents-addons-body .preview").click

        switch_to_window(windows.last)
        wait_for_document_loading

        expect(page).to have_css("h2", text: "見出し2")
        expect(page).to have_css("p", text: "内容が入ります。")
        expect(page).to have_css("h3", text: "見出し3")
        expect(page).to have_css("p", text: "内容が入ります。内容が入ります。")
        expect(page).to have_no_css("header h2", text: "カテゴリー")
      end
    end
  end

  context "with article form page" do
    let(:site) { cms_site }
    let(:node) { create :article_node_page, cur_site: site }
    let!(:layout) { create :cms_layout, cur_site: site }
    let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static', html: nil) }
    let!(:column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text')
    end
    let!(:column2) do
      create(:cms_column_date_field, cur_site: site, cur_form: form, required: "optional", order: 2)
    end
    let!(:column3) do
      create(:cms_column_url_field, cur_site: site, cur_form: form, required: "optional", order: 3, html_tag: '')
    end
    let!(:column4) do
      create(:cms_column_text_area, cur_site: site, cur_form: form, required: "optional", order: 4)
    end
    let!(:column5) do
      create(:cms_column_select, cur_site: site, cur_form: form, required: "optional", order: 5)
    end
    let!(:column6) do
      create(:cms_column_radio_button, cur_site: site, cur_form: form, required: "optional", order: 6)
    end
    let!(:column7) do
      create(:cms_column_check_box, cur_site: site, cur_form: form, required: "optional", order: 7)
    end
    let!(:column8) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, required: "optional", order: 8, file_type: "image")
    end
    let!(:column9) do
      create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 9)
    end
    let!(:column10) do
      create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional", order: 10)
    end
    let!(:column11) do
      create(:cms_column_list, cur_site: site, cur_form: form, required: "optional", order: 11)
    end
    let!(:column12) do
      create(:cms_column_table, cur_site: site, cur_form: form, required: "optional", order: 12)
    end
    let!(:column13) do
      create(:cms_column_youtube, cur_site: site, cur_form: form, required: "optional", order: 13)
    end
    let(:name) { unique_id }
    let(:column1_value) { unique_id }
    let(:column2_value) { "#{rand(2000..2050)}/01/01" }
    let(:column3_value) { "http://#{unique_id}.example.jp/#{unique_id}/" }
    let(:column4_value) { unique_id }
    let(:column5_value) { column5.select_options.sample }
    let(:column6_value) { column6.select_options.sample }
    let(:column7_value) { column7.select_options.sample }
    let(:column8_image_text) { unique_id }
    let(:column9_value) { unique_id }
    let(:column10_head) { "h1" }
    let(:column10_text) { unique_id }
    let(:column11_list) { unique_id }
    let(:column12_height) { rand(2..100) }
    let(:column12_width) { rand(2..100) }
    let(:column12_caption) { unique_id }
    let(:column13_youtube_id) { unique_id }
    let(:column13_url) { "https://www.youtube.com/watch?v=#{column13_youtube_id}" }
    let(:column13_embed_url) { "https://www.youtube.com/embed/#{column13_youtube_id}" }

    before { login_cms_user }
    before do
      node.st_form_ids = [ form.id ]
      node.save!
    end

    context "pc form preview" do
      it do
        #
        # Create
        #
        visit new_article_page_path(site: site, cid: node)

        within 'form#item-form' do
          fill_in 'item[name]', with: name

          page.first('#addon-basic a[onclick]').click
          fill_in "item[basename]", with: "sample"

          select layout.name, from: 'item[layout_id]'

          wait_event_to_fire("ss:formActivated") do
            page.accept_confirm(I18n.t("cms.confirm.change_form")) do
              select form.name, from: 'in_form_id'
            end
          end

          expect(page).to have_css("#addon-cms-agents-addons-form-page .addon-head", text: form.name)

          within ".column-value-cms-column-textfield" do
            fill_in "item[column_values][][in_wrap][value]", with: column1_value
          end
          within ".column-value-cms-column-datefield" do
            fill_in "item[column_values][][in_wrap][date]", with: column2_value
          end
          within ".column-value-cms-column-urlfield" do
            fill_in "item[column_values][][in_wrap][value]", with: column3_value
          end
          within ".column-value-cms-column-textarea" do
            fill_in "item[column_values][][in_wrap][value]", with: column4_value
          end
          within ".column-value-cms-column-select" do
            select column5_value, from: "item[column_values][][in_wrap][value]"
          end
          within ".column-value-cms-column-radiobutton" do
            first(:field, type: "radio", with: column6_value).click
          end
          within ".column-value-cms-column-checkbox" do
            first(:field, name: "item[column_values][][in_wrap][values][]", with: column7_value).click
          end
          within ".column-value-cms-column-fileupload" do
            fill_in "item[column_values][][in_wrap][file_label]", with: column8_image_text
            wait_cbox_open { click_on I18n.t("ss.links.upload") }
          end
        end

        wait_for_cbox do
          attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
          click_on I18n.t('ss.buttons.attach')
        end

        within 'form#item-form' do
          within ".column-value-cms-column-free" do
            fill_in_ckeditor "item[column_values][][in_wrap][value]", with: column9_value
          end

          within ".column-value-cms-column-headline" do
            select column10_head, from: "item[column_values][][in_wrap][head]"
            fill_in "item[column_values][][in_wrap][text]", with: column10_text
          end
          within ".column-value-cms-column-list" do
            fill_in "item[column_values][][in_wrap][lists][]", with: column11_list
          end
          within ".column-value-cms-column-table" do
            find("input.height").set(column12_height)
            find("input.width").set(column12_width)
            find("input.caption").set(column12_caption)
            click_on I18n.t("cms.column_table.create")
          end
          within ".column-value-cms-column-youtube" do
            fill_in "item[column_values][][in_wrap][url]", with: column13_url
          end
        end

        page.first("#addon-cms-agents-addons-form-page .preview").click

        switch_to_window(windows.last)
        wait_for_document_loading

        expect(page).to have_css("div", text: column1_value)
        expect(page).to have_css("div", text: I18n.l(column2_value.to_date, format: :long))
        expect(page).to have_css("div", text: column3_value)
        expect(page).to have_css("div", text: column4_value)
        expect(page).to have_css("div", text: column5_value)
        expect(page).to have_css("div", text: column6_value)
        expect(page).to have_css("div", text: column7_value)
        expect(page).to have_css("img[alt=\"#{column8_image_text}\"]")
        expect(page).to have_css("div", text: column9_value)
        expect(page).to have_css("h1", text: column10_text)
        expect(page).to have_css("div", text: column11_list)
        expect(page).to have_css("div", text: column12_caption)
        expect(page).to have_css("iframe[src=\"#{column13_embed_url}\"]")

        switch_to_window(windows.first)
        wait_for_document_loading

        within "form#item-form" do
          click_on I18n.t('ss.buttons.draft_save')
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        expect(Article::Page.count).to eq 1

        click_on I18n.t('ss.links.edit')
        page.first("#addon-cms-agents-addons-form-page .preview").click

        switch_to_window(windows.last)
        wait_for_document_loading

        expect(page).to have_css("div", text: column1_value)
        expect(page).to have_css("div", text: I18n.l(column2_value.to_date, format: :long))
        expect(page).to have_css("div", text: column3_value)
        expect(page).to have_css("div", text: column4_value)
        expect(page).to have_css("div", text: column5_value)
        expect(page).to have_css("div", text: column6_value)
        expect(page).to have_css("div", text: column7_value)
        expect(page).to have_css("img[alt=\"#{column8_image_text}\"]")
        expect(page).to have_css("div", text: column9_value)
        expect(page).to have_css("h1", text: column10_text)
        expect(page).to have_css("div", text: column11_list)
        expect(page).to have_css("div", text: column12_caption)
        expect(page).to have_css("iframe[src=\"#{column13_embed_url}\"]")
      end
    end
  end
end
