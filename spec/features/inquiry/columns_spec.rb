require 'spec_helper'

describe "inquiry_columns", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:group0) { cms_group }
  let!(:group1) { create :cms_group, name: "#{group0.name}/#{unique_id}" }
  let!(:group2) { create :cms_group, name: "#{group0.name}/#{unique_id}" }

  context "with column editor" do
    let!(:role) do
      permissions = %w(read_private_cms_nodes read_other_inquiry_columns edit_other_inquiry_columns delete_other_inquiry_columns)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group1.id ] }

    before { login_user user }

    context "basic crud" do
      let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: [ group1.id, group2.id ] }
      let(:name) { unique_id }
      let(:html) { "<p>#{unique_id}</p>" }
      let(:state) { "public" }
      let(:state_label) { I18n.t("ss.options.state.#{state}") }
      let(:order) { 0 }
      let(:input_type) { "text_field" }
      let(:input_type_label) { I18n.t("inquiry.options.input_type.#{input_type}") }
      let(:select_options) { Array.new(2) { "option-#{unique_id}" } }
      let(:required) { "required" }
      let(:required_label) { I18n.t("inquiry.options.required.#{required}") }
      let(:additional_attr) { "sample" }
      let(:input_confirm) { "disabled" }
      let(:input_confirm_label) { I18n.t("inquiry.options.input_confirm.#{input_confirm}") }
      let(:question) { "disabled" }
      let(:question_label) { I18n.t("ss.options.state.#{question}") }
      let(:max_upload_file_size) { 0 }
      let(:transfers_0_keyword) { "sample" }
      let(:transfers_0_email) { "sample@example.jp" }
      let(:name2) { "modify-#{name}" }

      it do
        visit inquiry_forms_path(site: site, cid: node)
        within first(".mod-navi") do
          click_on I18n.t("inquiry.column")
        end
        within '.gws-column-list-toolbar[data-placement="top"]' do
          click_on input_type_label
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within first('.gws-column-item') do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within first('.gws-column-item') do
          find('.btn-gws-column-item-detail').click
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          # fill_in_ckeditor "item[html]", with: html
          select state_label, from: 'item[state]'
          # fill_in "item[order]", with: order
          select input_type_label, from: 'item[input_type]'
          fill_in "item[select_options]", with: select_options.join("\n")
          select required_label, from: 'item[required]'
          fill_in "item[additional_attr]", with: additional_attr
          select input_confirm_label, from: 'item[input_confirm]'
          select question_label, from: 'item[question]'
          fill_in "item[max_upload_file_size]", with: max_upload_file_size
          fill_in "item[transfers][][keyword]", with: transfers_0_keyword
          fill_in "item[transfers][][email]", with: transfers_0_email

          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Inquiry::Column.all.count).to eq 1
        Inquiry::Column.all.first.tap do |column|
          expect(column.site_id).to eq site.id
          expect(column.name).to eq name
          # expect(column.html).to eq html
          expect(column.state).to eq state
          # expect(column.order).to eq order
          expect(column.input_type).to eq input_type
          expect(column.select_options).to eq select_options
          expect(column.required).to eq required
          expect(column.additional_attr).to eq additional_attr
          expect(column.input_confirm).to eq input_confirm
          expect(column.question).to eq question
          expect(column.max_upload_file_size).to eq max_upload_file_size
          expect(column.transfers).to have(1).items
          expect(column.transfers).to include("keyword" => transfers_0_keyword, "email" => transfers_0_email)
        end

        within first('.gws-column-item') do
          find('.gws-column-item-edit .btn').click
        end
        wait_for_all_turbo_frames

        within first('.gws-column-item') do
          fill_in "item[name]", with: name2
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Inquiry::Column.all.count).to eq 1
        Inquiry::Column.all.first.tap do |column|
          expect(column.name).to eq name2
        end

        within first('.gws-column-item') do
          page.accept_confirm do
            find('.btn-gws-column-item-delete').click
          end
        end
        wait_for_notice I18n.t('ss.notice.deleted')

        expect(Inquiry::Column.all.count).to eq 0
      end
    end

    context "inquiry under article node" do
      let!(:node) { create :article_node_page, cur_site: site, group_ids: [ group1.id, group2.id ] }
      let(:name) { unique_id }
      let(:html) { "<p>#{unique_id}</p>" }
      let(:state) { "public" }
      let(:state_label) { I18n.t("ss.options.state.#{state}") }
      let(:order) { 0 }
      let(:input_type) { "text_field" }
      let(:input_type_label) { I18n.t("inquiry.options.input_type.#{input_type}") }
      let(:select_options) { Array.new(2) { "option-#{unique_id}" } }
      let(:required) { "required" }
      let(:required_label) { I18n.t("inquiry.options.required.#{required}") }
      let(:additional_attr) { "sample" }
      let(:input_confirm) { "disabled" }
      let(:input_confirm_label) { I18n.t("inquiry.options.input_confirm.#{input_confirm}") }
      let(:question) { "disabled" }
      let(:question_label) { I18n.t("ss.options.state.#{question}") }
      let(:max_upload_file_size) { 0 }
      let(:transfers_0_keyword) { "sample" }
      let(:transfers_0_email) { "sample@example.jp" }
      let(:name2) { "modify-#{name}" }

      it do
        visit inquiry_forms_path(site: site, cid: node)
        within first(".mod-navi") do
          click_on I18n.t("inquiry.column")
        end

        within '.gws-column-list-toolbar[data-placement="top"]' do
          click_on input_type_label
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within first('.gws-column-item') do
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t('ss.notice.saved')

        within first('.gws-column-item') do
          find('.btn-gws-column-item-detail').click
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          # fill_in_ckeditor "item[html]", with: html
          select state_label, from: 'item[state]'
          # fill_in "item[order]", with: order
          select input_type_label, from: 'item[input_type]'
          fill_in "item[select_options]", with: select_options.join("\n")
          select required_label, from: 'item[required]'
          fill_in "item[additional_attr]", with: additional_attr
          select input_confirm_label, from: 'item[input_confirm]'
          select question_label, from: 'item[question]'
          fill_in "item[max_upload_file_size]", with: max_upload_file_size
          fill_in "item[transfers][][keyword]", with: transfers_0_keyword
          fill_in "item[transfers][][email]", with: transfers_0_email

          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Inquiry::Column.all.count).to eq 1
        Inquiry::Column.all.first.tap do |column|
          expect(column.site_id).to eq site.id
          expect(column.name).to eq name
          # expect(column.html).to eq html
          expect(column.state).to eq state
          # expect(column.order).to eq order
          expect(column.input_type).to eq input_type
          expect(column.select_options).to eq select_options
          expect(column.required).to eq required
          expect(column.additional_attr).to eq additional_attr
          expect(column.input_confirm).to eq input_confirm
          expect(column.question).to eq question
          expect(column.max_upload_file_size).to eq max_upload_file_size
          expect(column.transfers).to have(1).items
          expect(column.transfers).to include("keyword" => transfers_0_keyword, "email" => transfers_0_email)
        end

        within first('.gws-column-item') do
          find('.gws-column-item-edit .btn').click
        end
        wait_for_all_turbo_frames

        within first('.gws-column-item') do
          fill_in "item[name]", with: name2
          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Inquiry::Column.all.count).to eq 1
        Inquiry::Column.all.first.tap do |column|
          expect(column.name).to eq name2
        end

        within first('.gws-column-item') do
          page.accept_confirm do
            find('.btn-gws-column-item-delete').click
          end
        end
        wait_for_notice I18n.t('ss.notice.deleted')

        expect(Inquiry::Column.all.count).to eq 0
      end
    end

    # ネットの情報を参考にドラッグ&ドロップによる並び替えをテストしようとしたけどうまく行かず
    xcontext "reorder by drag & drop" do
      let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: [ group1.id, group2.id ] }

      before do
        node.columns.create! attributes_for(:inquiry_column_name).reverse_merge(cur_site: site)
        node.columns.create! attributes_for(:inquiry_column_email).reverse_merge(cur_site: site)
        node.reload
      end

      it do
        visit inquiry_columns_path(site: site, cid: node)

        name_column = node.columns[0]
        email_column = node.columns[1]

        name_column_el = page.first(".gws-column-item[data-id='#{name_column.id}']")
        name_column_handle_el = name_column_el.first(".gws-column-item-drag-handle-icon")
        email_column_el = page.first(".gws-column-item[data-id='#{email_column.id}']")
        email_column_handle_el = email_column_el.first(".gws-column-item-drag-handle-icon")
        page.driver.browser.action.tap do |action_builder|
          # action_builder
          #   .click_and_hold(name_column_handle_el.native)
          #   .pause(duration: 0.1)
          #   .move_to(email_column_handle_el.native, duration: 3)
          #   .release
          #   .perform
          down_by = email_column_handle_el.native.location.y - name_column_handle_el.native.location.y
          action_builder
            .scroll_to(email_column_handle_el.native)
            .drag_and_drop_by(name_column_handle_el.native, 0, down_by)
            .perform
        end
        wait_for_notice I18n.t("gws/column.notice.reordered")

        node.columns.where(id: name_column.id).first.tap do |name_column_after_reorder|
          expect(name_column_after_reorder.order).to eq 20
        end
        node.columns.where(id: email_column.id).first.tap do |email_column_after_reorder|
          expect(email_column_after_reorder.order).to eq 10
        end
      end
    end
  end

  context "with column reader" do
    let!(:role) do
      permissions = %w(read_private_cms_nodes read_other_inquiry_columns)
      create :cms_role, cur_site: site, name: unique_id, permissions: permissions
    end
    let!(:user) { create :cms_test_user, cur_site: site, cms_role_ids: [ role.id ], group_ids: [ group1.id ] }

    before { login_user user }

    context "basic crud" do
      let!(:node) { create :inquiry_node_form, cur_site: site, group_ids: [ group1.id, group2.id ] }

      before do
        node.columns.create! attributes_for(:inquiry_column_name).reverse_merge(cur_site: site)
        node.columns.create! attributes_for(:inquiry_column_email).reverse_merge(cur_site: site)
        node.reload
      end

      it do
        visit inquiry_forms_path(site: site, cid: node)
        within first(".mod-navi") do
          click_on I18n.t("inquiry.column")
        end

        name_column = node.columns[0]
        expect(page).to have_css(".gws-column-item[data-id='#{name_column.id}']", text: name_column.name)
        email_column = node.columns[1]
        expect(page).to have_css(".gws-column-item[data-id='#{email_column.id}']", text: email_column.name)

        expect(page).to have_no_css(".gws-column-list-toolbar")
        expect(page).to have_no_css(".gws-column-item-drag-handle")
        expect(page).to have_no_css(".gws-column-item-toolbar-item")
        expect(page).to have_no_css(".gws-column-item-edit")
        expect(page).to have_no_css(".gws-column-item-detail")
        expect(page).to have_no_css(".gws-column-item-delete")
      end
    end
  end
end
