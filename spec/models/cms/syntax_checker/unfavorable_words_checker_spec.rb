require 'spec_helper'

describe Cms::SyntaxChecker::UnfavorableWordsChecker, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:unfavorable_word) { create(:cms_unfavorable_word, cur_site: site) }
  let(:words) { unfavorable_word.body.split(/\R+/) }
  let(:longest_word) { words.max_by(&:length) }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }

  context "with cms/column/text_field" do
    let!(:column1) { create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: 'text') }
    let!(:item) do
      build(
        :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
        column_values: [
          column1.value_type.new(column: column1, value: longest_word)
        ]
      )
    end

    it do
      context = Cms::SyntaxChecker.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

      expect(context.errors).to have(1).items
      context.errors.first.tap do |error|
        expect(error.id).to eq "column-value-#{item.column_values.first.id}"
        expect(error.name).to eq column1.name
        expect(error.idx).to be_blank
        expect(error.code).to eq longest_word
        expect(error.full_message).to eq I18n.t('errors.messages.unfavorable_word')
        expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.unfavorable_word')
        expect(error.corrector).to be_blank
        expect(error.corrector_params).to be_blank
      end
    end
  end

  context "with cms/column/file_upload (image or attachment or banner)" do
    let(:file_type) { %w(image attachment banner).sample }
    let!(:column1) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: file_type)
    end
    let(:file1) do
      content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
    end
    let!(:item) do
      build(
        :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
        column_values: [
          column1.value_type.new(column: column1, file_id: file1.id, file_label: longest_word)
        ]
      )
    end

    it do
      context = Cms::SyntaxChecker.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

      expect(context.errors).to have(1).items
      context.errors.first.tap do |error|
        expect(error.id).to eq "column-value-#{item.column_values.first.id}"
        expect(error.name).to eq column1.name
        expect(error.idx).to be_blank
        expect(error.code).to eq longest_word
        expect(error.full_message).to eq I18n.t('errors.messages.unfavorable_word')
        expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.unfavorable_word')
        expect(error.corrector).to be_blank
        expect(error.corrector_params).to be_blank
      end
    end
  end

  context "with cms/column/file_upload (video)" do
    let(:file_type) { "video" }
    let!(:column1) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: file_type)
    end
    let(:file1) do
      content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
      tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
    end
    let!(:item) do
      build(
        :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
        column_values: [
          column1.value_type.new(column: column1, file_id: file1.id, text: longest_word)
        ]
      )
    end

    it do
      context = Cms::SyntaxChecker.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

      expect(context.errors).to have(1).items
      context.errors.first.tap do |error|
        expect(error.id).to eq "column-value-#{item.column_values.first.id}"
        expect(error.name).to eq column1.name
        expect(error.idx).to be_blank
        expect(error.code).to eq longest_word
        expect(error.full_message).to eq I18n.t('errors.messages.unfavorable_word')
        expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.unfavorable_word')
        expect(error.corrector).to be_blank
        expect(error.corrector_params).to be_blank
      end
    end
  end

  context "with cms/column/url_field2" do
    let!(:column1) do
      create(:cms_column_url_field2, cur_site: site, cur_form: form)
    end
    let!(:item) do
      build(
        :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
        column_values: [
          column1.value_type.new(column: column1, link_label: longest_word)
        ]
      )
    end

    it do
      context = Cms::SyntaxChecker.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

      expect(context.errors).to have(1).items
      context.errors.first.tap do |error|
        expect(error.id).to eq "column-value-#{item.column_values.first.id}"
        expect(error.name).to eq column1.name
        expect(error.idx).to be_blank
        expect(error.code).to eq longest_word
        expect(error.full_message).to eq I18n.t('errors.messages.unfavorable_word')
        expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.unfavorable_word')
        expect(error.corrector).to be_blank
        expect(error.corrector_params).to be_blank
      end
    end
  end

  context "with cms/column/headline" do
    let!(:column1) { create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional") }
    let!(:item) do
      build(
        :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
        column_values: [
          column1.value_type.new(column: column1, head: "h2", text: longest_word)
        ]
      )
    end

    it do
      context = Cms::SyntaxChecker.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

      expect(context.errors).to have(1).items
      context.errors.first.tap do |error|
        expect(error.id).to eq "column-value-#{item.column_values.first.id}"
        expect(error.name).to eq column1.name
        expect(error.idx).to be_blank
        expect(error.code).to eq longest_word
        expect(error.full_message).to eq I18n.t('errors.messages.unfavorable_word')
        expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.unfavorable_word')
        expect(error.corrector).to be_blank
        expect(error.corrector_params).to be_blank
      end
    end
  end

  context "with cms/column/list" do
    let!(:column1) { create(:cms_column_list, cur_site: site, cur_form: form) }
    let!(:item) do
      build(
        :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
        column_values: [
          column1.value_type.new(column: column1, lists: [ longest_word ])
        ]
      )
    end

    it do
      context = Cms::SyntaxChecker.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

      expect(context.errors).to have(1).items
      context.errors.first.tap do |error|
        expect(error.id).to eq "column-value-#{item.column_values.first.id}"
        expect(error.name).to eq column1.name
        expect(error.idx).to be_blank
        expect(error.code).to eq longest_word
        expect(error.full_message).to eq I18n.t('errors.messages.unfavorable_word')
        expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.unfavorable_word')
        expect(error.corrector).to be_blank
        expect(error.corrector_params).to be_blank
      end
    end
  end
end
