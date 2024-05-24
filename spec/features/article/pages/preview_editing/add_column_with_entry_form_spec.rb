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

  let!(:node2) { create :article_node_page, cur_site: site, group_ids: [cms_group.id] }
  let!(:selectable_page1) { create :article_page, cur_site: site, cur_node: node2, state: "public" }
  let!(:selectable_page2) { create :article_page, cur_site: site, cur_node: node2, state: "public" }
  let!(:selectable_page3) { create :article_page, cur_site: site, cur_node: node2, state: "public" }
  let!(:selectable_page4) { create :article_page, cur_site: site, cur_node: node2, state: "closed" }

  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'entry', html: nil }
  let!(:column1) do
    create(
      :cms_column_text_field, cur_site: site, cur_form: form, required: "optional", order: 1, input_type: 'text', max_length: 80
    )
  end
  let!(:column2) do
    create(:cms_column_date_field, cur_site: site, cur_form: form, required: "optional", order: 2)
  end
  let!(:column3) do
    create(:cms_column_url_field2, cur_site: site, cur_form: form, required: "optional", order: 3, html_tag: '')
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
  let!(:column14) do
    create(:cms_column_select_page, cur_site: site, cur_form: form, required: "optional", order: 14, node_ids: [node2.id])
  end

  before do
    site.set(auto_keywords: 'enabled', auto_description: 'enabled')

    node.st_form_ids = [ form.id ]
    node.save!

    login_cms_user
  end

  describe "add column with entry form on preview editing" do
    shared_examples "what add column with entry form is" do
      let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout: layout, form: form, state: state) }
      let(:column1_value1) { unique_id }
      let(:column2_date1) { Date.new(rand(2000..2050), 1, 1) }
      let(:column2_value1) { I18n.l(column2_date1, format: :picker) }
      let(:column3_label1) { unique_id }
      let(:column3_url1) { "/#{unique_id}/" }
      let(:column4_value1) { Array.new(2) { unique_id } }
      let(:column5_value1) { column5.select_options.sample }
      let(:column6_value1) { column6.select_options.sample }
      let(:column7_value1) { column7.select_options.sample }
      let(:column8_image_text1) { unique_id }
      let(:column9_value1) { unique_id }
      # let(:column10_head1) { %w(h1 h2 h3 h4 h5).sample }
      let(:column10_head1) { %w(h1 h2).sample }
      let(:column10_text1) { unique_id }
      let(:column11_list1) { unique_id }
      let(:column12_height1) { rand(2..5) }
      let(:column12_width1) { rand(2..5) }
      let(:column12_caption1) { unique_id }
      let(:column13_youtube_id1) { unique_id }
      let(:column13_url1) { "https://www.youtube.com/watch?v=#{column13_youtube_id1}" }
      let(:column14_page1) { [ selectable_page1, selectable_page2, selectable_page3 ].sample }

      it do
        visit cms_preview_path(site: site, path: item.preview_path)

        # start preview editing
        wait_event_to_fire "ss:inplaceModeChanged" do
          within "#ss-preview" do
            within ".ss-preview-wrap-column-edit-mode" do
              click_on I18n.t("cms.inplace_edit")
            end
          end
        end

        # #1: cms_column_text_field
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column1.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-textfield" do
              fill_in "item[column_values][][in_wrap][value]", with: column1_value1
            end

            click_on state == "public" ? I18n.t("cms.buttons.save_as_branch") : I18n.t("ss.buttons.save")
            # expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            # expect(page).to have_css("#errorFormChecker", text: I18n.t("errors.template.no_errors"))
            # expect(page).to have_css("#errorLinkChecker", text: I18n.t("errors.template.check_links"))
          end
        end
        if state == "public"
          expect(page).to have_css(".ss-preview-notice-wrap", text: I18n.t("workflow.notice.created_branch_page"))
        else
          expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
          page.execute_script('$("#ss-notice").remove();')
        end
        expect(page).to have_css("[data-column-name='#{column1.name}']", text: column1_value1)

        item.reload
        if state == "public"
          expect(item.branches.count).to eq 1
          now_editing_item = item.branches.first
        else
          now_editing_item = item
        end

        expect(now_editing_item.column_values.count).to eq 1
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value1 = column_values[0]
        expect(column_value1.column_id).to eq column1.id
        expect(column_value1.value).to eq column1_value1
        expect(column_value1.order).to eq 0

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #2: cms_column_date_field
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column2.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-datefield" do
              fill_in "item[column_values][][in_wrap][date]", with: column2_value1
            end

            click_on I18n.t("ss.buttons.save")
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column2.name}']", text: I18n.l(column2_date1, format: :long))

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 2
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value2 = column_values.last
        expect(column_value2.column_id).to eq column2.id
        expect(column_value2.date).to eq column2_date1.in_time_zone
        expect(column_value2.order).to eq 1

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #3: cms_column_url_field2
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column3.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-urlfield2" do
              fill_in "item[column_values][][in_wrap][link_label]", with: column3_label1
              fill_in "item[column_values][][in_wrap][link_url]", with: column3_url1
            end

            click_on I18n.t("ss.buttons.save")
            # expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            # expect(page).to have_css("#errorLinkChecker", text: I18n.t("errors.template.check_links"))
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column3.name}']", text: column3_label1)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 3
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value3 = column_values.last
        expect(column_value3.column_id).to eq column3.id
        expect(column_value3.link_label).to eq column3_label1
        expect(column_value3.link_url).to eq column3_url1
        expect(column_value3.order).to eq 2

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #4: cms_column_text_area
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column4.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-textarea" do
              fill_in "item[column_values][][in_wrap][value]", with: column4_value1.join("\n")
            end

            click_on I18n.t("ss.buttons.save")
            # expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            # expect(page).to have_css("#errorLinkChecker", text: I18n.t("errors.template.check_links"))
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column4.name}']", text: column4_value1.last)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 4
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value4 = column_values.last
        expect(column_value4.column_id).to eq column4.id
        expect(column_value4.value).to eq column4_value1.join("\r\n")
        expect(column_value4.order).to eq 3

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #5: cms_column_select
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column5.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-select" do
              select column5_value1, from: "item[column_values][][in_wrap][value]"
            end

            click_on I18n.t("ss.buttons.save")
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column5.name}']", text: column5_value1)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 5
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value5 = column_values.last
        expect(column_value5.column_id).to eq column5.id
        expect(column_value5.value).to eq column5_value1
        expect(column_value5.order).to eq 4

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #6: cms_column_radio_button
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column6.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-radiobutton" do
              first(:field, type: "radio", with: column6_value1).click
            end

            click_on I18n.t("ss.buttons.save")
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column6.name}']", text: column6_value1)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 6
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value6 = column_values.last
        expect(column_value6.column_id).to eq column6.id
        expect(column_value6.value).to eq column6_value1
        expect(column_value6.order).to eq 5

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #7: cms_column_check_box
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column7.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-checkbox" do
              first(:field, name: "item[column_values][][in_wrap][values][]", with: column7_value1).click
            end

            click_on I18n.t("ss.buttons.save")
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column7.name}']", text: column7_value1)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 7
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value7 = column_values.last
        expect(column_value7.column_id).to eq column7.id
        expect(column_value7.values).to eq [ column7_value1 ]
        expect(column_value7.order).to eq 6

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #8: cms_column_file_upload
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column8.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-fileupload" do
              fill_in "item[column_values][][in_wrap][file_label]", with: column8_image_text1
              wait_cbox_open { click_on I18n.t("ss.links.upload") }
            end
          end
          wait_for_cbox do
            attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
            click_on I18n.t('ss.buttons.attach')
          end
          within 'form#item-form' do
            within ".column-value-cms-column-fileupload" do
              expect(page).to have_content("keyvisual.gif")
            end

            click_on I18n.t("ss.buttons.save")
            # expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            # expect(page).to have_css("#errorLinkChecker", text: I18n.t("errors.template.check_links"))
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column8.name}'] img[alt='#{column8_image_text1}']")

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 8
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value8 = column_values.last
        expect(column_value8.column_id).to eq column8.id
        expect(column_value8.file_label).to eq column8_image_text1
        expect(column_value8.file.name).to eq 'keyvisual.gif'
        expect(column_value8.file.owner_item_id).to eq now_editing_item.id
        expect(column_value8.order).to eq 7

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #9: cms_column_free
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column9.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-free" do
              fill_in_ckeditor "item[column_values][][in_wrap][value]", with: column9_value1
              wait_cbox_open { click_on I18n.t("ss.links.upload") }
            end
          end
          wait_for_cbox do
            attach_file 'item[in_files][]', "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
            click_on I18n.t('ss.buttons.attach')
          end
          within "#item-form" do
            within ".column-value-cms-column-free" do
              expect(page).to have_content("keyvisual.gif")
              wait_for_ckeditor_event "item[column_values][][in_wrap][value]", "afterInsertHtml" do
                click_on I18n.t("sns.image_paste")
              end
            end
            click_on I18n.t("ss.buttons.ignore_alerts_and_save")
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column9.name}']", text: column9_value1)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 9
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value9 = column_values.last
        expect(column_value9.column_id).to eq column9.id
        expect(column_value9.value).to include column9_value1
        expect(column_value9.file_ids).to have(1).items
        column9_file1 = column_value9.files.first
        expect(column9_file1.name).to eq "keyvisual.gif"
        expect(column9_file1.owner_item_id).to eq now_editing_item.id
        expect(column_value9.value).to include column9_file1.url
        expect(column_value9.order).to eq 8

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #10: cms_column_headline
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column10.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-headline" do
              select column10_head1, from: "item[column_values][][in_wrap][head]"
              fill_in "item[column_values][][in_wrap][text]", with: column10_text1
            end

            click_on I18n.t("ss.buttons.save")
            # expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            # expect(page).to have_css("#errorLinkChecker", text: I18n.t("errors.template.check_links"))
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column10.name}']", text: column10_text1)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 10
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value10 = column_values.last
        expect(column_value10.column_id).to eq column10.id
        expect(column_value10.head).to eq column10_head1
        expect(column_value10.text).to eq column10_text1
        expect(column_value10.order).to eq 9

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #11: cms_column_list
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column11.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-list" do
              fill_in "item[column_values][][in_wrap][lists][]", with: column11_list1
            end

            click_on I18n.t("ss.buttons.save")
            # expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            # expect(page).to have_css("#errorLinkChecker", text: I18n.t("errors.template.check_links"))
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column11.name}']", text: column11_list1)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 11
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value11 = column_values.last
        expect(column_value11.column_id).to eq column11.id
        expect(column_value11.lists).to include column11_list1
        expect(column_value11.order).to eq 10

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #12: cms_column_table
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column12.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          within "#item-form" do
            within ".column-value-cms-column-table" do
              find("input.height").set(column12_height1)
              find("input.width").set(column12_width1)
              find("input.caption").set(column12_caption1)
              click_on I18n.t("cms.column_table.create")
            end

            click_on I18n.t("ss.buttons.save")
            # expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
            # expect(page).to have_css("#errorLinkChecker", text: I18n.t("errors.template.check_links"))
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column12.name}']", text: column12_caption1)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 12
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value12 = column_values.last
        expect(column_value12.column_id).to eq column12.id
        expect(column_value12.order).to eq 11

        puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #13: cms_column_youtube
        #wait_event_to_fire("ss:inplaceEditFrameInitialized") do
        #  within_frame page.first("#ss-preview-form-palette") do
        #    within ".column-value-palette" do
        #      click_on column13.name
        #    end
        #  end
        #end
        #within_frame page.first("#ss-preview-dialog-frame") do
        #  within "#item-form" do
        #    within ".column-value-cms-column-youtube" do
        #      fill_in "item[column_values][][in_wrap][url]", with: column13_url1
        #    end
        #
        #    click_on I18n.t("ss.buttons.save")
        #    # expect(page).to have_css("#errorSyntaxChecker", text: I18n.t("errors.template.no_errors"))
        #    # expect(page).to have_css("#errorLinkChecker", text: I18n.t("errors.template.check_links"))
        #  end
        #end
        #expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        #page.execute_script('$("#ss-notice").remove();')
        #expect(page).to have_css("[data-column-name='#{column13.name}'] iframe[src='https://www.youtube.com/embed/#{column13_youtube_id1}']")

        #now_editing_item.reload
        #expect(now_editing_item.column_values.count).to eq 13
        #column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        #column_value13 = column_values.last
        #expect(column_value13.column_id).to eq column13.id
        #expect(column_value13.youtube_id).to eq column13_youtube_id1
        #expect(column_value13.order).to eq 12
        #
        #puts_console_logs if capture_console_logs.any? { |log| log =~ /Uncaught/i }

        # #14: cms_column_select_page
        wait_event_to_fire("ss:inplaceEditFrameInitialized") do
          within_frame page.first("#ss-preview-form-palette") do
            within ".column-value-palette" do
              click_on column14.name
            end
          end
        end
        within_frame page.first("#ss-preview-dialog-frame") do
          wait_cbox_open { click_on I18n.t("cms.apis.pages.index") }
          wait_for_cbox do
            expect(page).to have_css(".list-item", text: selectable_page1.name)
            expect(page).to have_css(".list-item", text: selectable_page2.name)
            expect(page).to have_css(".list-item", text: selectable_page3.name)
            expect(page).to have_no_css(".list-item", text: selectable_page4.name)
            click_on column14_page1.name
          end
          within 'form#item-form' do
            within ".column-value-cms-column-selectpage " do
              expect(page).to have_css(".ajax-selected", text: column14_page1.name)
            end
            click_on I18n.t("ss.buttons.save")
          end
        end
        expect(page).to have_css("#ss-notice", text: I18n.t("ss.notice.saved"))
        page.execute_script('$("#ss-notice").remove();')
        expect(page).to have_css("[data-column-name='#{column14.name}']", text: column14_page1.name)

        now_editing_item.reload
        expect(now_editing_item.column_values.count).to eq 13
        column_values = now_editing_item.column_values.order_by(order: 1, name: 1).to_a
        column_value14 = column_values.last
        expect(column_value14.column_id).to eq column14.id
        expect(column_value14.page_id).to eq column14_page1.id
        expect(column_value14.order).to eq 12
      end
    end

    context "with public page" do
      let(:state) { "public" }

      it_behaves_like "what add column with entry form is"
    end

    context "with closed page" do
      let(:state) { "closed" }

      it_behaves_like "what add column with entry form is"
    end
  end
end
