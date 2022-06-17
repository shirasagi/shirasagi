require 'spec_helper'

describe "inquiry_columns", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }

  before { login_cms_user }

  context "basic crud" do
    let!(:node) { create :inquiry_node_form }
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
      visit inquiry_columns_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in_ckeditor "item[html]", with: html
        select state_label, from: 'item[state]'
        fill_in "item[order]", with: order
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
        expect(column.html).to eq html
        expect(column.state).to eq state
        expect(column.order).to eq order
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

      visit inquiry_columns_path(site: site, cid: node)
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Inquiry::Column.all.count).to eq 1
      Inquiry::Column.all.first.tap do |column|
        expect(column.name).to eq name2
      end

      visit inquiry_columns_path(site: site, cid: node)
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Inquiry::Column.all.count).to eq 0
    end
  end

  context "inquiry under article node" do
    let!(:node) { create :article_node_page }
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
      visit inquiry_columns_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in_ckeditor "item[html]", with: html
        select state_label, from: 'item[state]'
        fill_in "item[order]", with: order
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
        expect(column.html).to eq html
        expect(column.state).to eq state
        expect(column.order).to eq order
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

      visit inquiry_columns_path(site: site, cid: node)
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Inquiry::Column.all.count).to eq 1
      Inquiry::Column.all.first.tap do |column|
        expect(column.name).to eq name2
      end

      visit inquiry_columns_path(site: site, cid: node)
      click_on name2
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Inquiry::Column.all.count).to eq 0
    end
  end

  context "lgwan" do
    let!(:node) { create :inquiry_node_form }

    context "lgwan enabled" do
      before do
        SS.config.replace_value_at(:lgwan, :disable, false)
      end

      after do
        SS.config.replace_value_at(:lgwan, :disable, true)
      end

      it do
        visit inquiry_columns_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in_ckeditor "item[html]", with: "<p>sample</p>"
          select I18n.t('ss.options.state.public'), from: 'item_state'
          fill_in "item[order]", with: 0
          select [I18n.t('inquiry.options.input_type.upload_file'), I18n.t('inquiry.cannot_use')].join, from: 'item_input_type'
          fill_in "item[select_options]", with: "sample"
          select I18n.t('inquiry.options.required.required'), from: 'item_required'
          fill_in "item[additional_attr]", with: "sample"
          select I18n.t('inquiry.options.input_confirm.disabled'), from: 'item_input_confirm'
          select I18n.t('ss.options.state.disabled'), from: 'item_question'
          fill_in "item[max_upload_file_size]", with: 0
          fill_in "item[transfers][][keyword]", with: "sample"
          fill_in "item[transfers][][email]", with: "sample@example.jp"

          click_on I18n.t('ss.buttons.save')
        end
        error = [Inquiry::Column.t(:input_type), I18n.t('errors.messages.cannot_use_upload_file')].join
        expect(page).to have_selector('#errorExplanation ul li', count: 1)
        expect(page).to have_css("#errorExplanation", text: error)

        expect(Inquiry::Column.all.count).to eq 0
      end
    end

    context "lgwan disabled" do
      before do
        SS.config.replace_value_at(:lgwan, :disable, true)
      end

      it do
        visit inquiry_columns_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          fill_in_ckeditor "item[html]", with: "<p>sample</p>"
          select I18n.t('ss.options.state.public'), from: 'item_state'
          fill_in "item[order]", with: 0
          select I18n.t('inquiry.options.input_type.upload_file'), from: 'item_input_type'
          fill_in "item[select_options]", with: "sample"
          select I18n.t('inquiry.options.required.required'), from: 'item_required'
          fill_in "item[additional_attr]", with: "sample"
          select I18n.t('inquiry.options.input_confirm.disabled'), from: 'item_input_confirm'
          select I18n.t('ss.options.state.disabled'), from: 'item_question'
          fill_in "item[max_upload_file_size]", with: 0
          fill_in "item[transfers][][keyword]", with: "sample"
          fill_in "item[transfers][][email]", with: "sample@example.jp"

          click_on I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")

        expect(Inquiry::Column.all.count).to eq 1
      end
    end
  end
end
