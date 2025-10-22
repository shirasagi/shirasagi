require 'spec_helper'

describe Cms::SyntaxChecker, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  describe ".check_page" do
    context "with cms/addon/body" do
      let(:item_html1) { '<a href="/docs/2892.html">利用規約</a>' }
      let(:item_html2) { '<a href="/docs/2892.html">個人情報保護</a>' }
      let(:item_html3) { '<a href="/docs/2893.html">サイトマップ</a>' }
      let(:separator) { " | " }
      let(:item_html) { "<div>#{[ item_html1, item_html2, item_html3 ].join(separator)}</div>" }

      let!(:layout) { create_cms_layout cur_site: site }
      let!(:node) { create :article_node_page, cur_site: site, layout: layout }
      let!(:item) { create :article_page, cur_site: site, cur_node: node, layout: layout, html: item_html }

      it do
        context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: page.html)

        expect(context.errors).to have(1).items
        context.errors.first.tap do |error|
          expect(error.id).to eq "item_html"
          expect(error.name).to eq item.class.t(:html)
          expect(error.idx).to be >= 0
          expect(error.code).to include(item_html1, item_html2)
          expect(error.full_message).to eq I18n.t('errors.messages.invalid_adjacent_a')
          expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.invalid_adjacent_a')
          expect(error.corrector).to eq "Cms::SyntaxChecker::AdjacentAChecker"
          expect(error.corrector_params).to be_blank
        end
      end
    end

    context "with cms/addon/form/page" do
      context "with cms/column/text_field" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
        let!(:column1) { create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: 'text') }

        let!(:layout) { create_cms_layout cur_site: site }
        let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }
        let(:text) { Array.new(2) { unique_id }.join(Cms::SyntaxChecker::FULL_WIDTH_SPACE) }
        let!(:item) do
          create(
            :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
            column_values: [
              column1.value_type.new(column: column1, value: text)
            ]
          )
        end

        it do
          context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq "column-value-#{item.column_values.first.id}"
            expect(error.name).to eq column1.name
            expect(error.idx).to be_blank
            expect(error.code).to eq text
            expect(error.full_message).to eq I18n.t('errors.messages.check_interword_space')
            expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
            expect(error.corrector).to eq "Cms::SyntaxChecker::InterwordSpaceChecker"
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "with cms/column/file_upload (image or banner)" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
        let(:file_type) { %w(image banner).sample }
        let!(:column1) do
          create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: file_type)
        end

        let!(:layout) { create_cms_layout cur_site: site }
        let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }
        let(:file1) do
          content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
        end
        let!(:item) do
          create(
            :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
            column_values: [
              column1.value_type.new(column: column1, file_id: file1.id, link_url: unique_url)
            ]
          )
        end

        it do
          context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq "column-value-#{item.column_values.first.id}"
            expect(error.name).to eq column1.name
            expect(error.idx).to be_blank
            expect(error.code).to be_blank
            expect(error.full_message).to eq I18n.t("cms.column_file_upload.image.file_label_place_holder")
            expect(error.detail).to be_blank
            expect(error.corrector).to be_blank
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "with cms/column/file_upload (attachment)" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
        let(:file_type) { "attachment" }
        let!(:column1) do
          create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: file_type)
        end

        let!(:layout) { create_cms_layout cur_site: site }
        let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }
        let(:file1) do
          content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
        end
        let!(:item) do
          create(
            :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
            column_values: [
              column1.value_type.new(column: column1, file_id: file1.id)
            ]
          )
        end

        it do
          context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq "column-value-#{item.column_values.first.id}"
            expect(error.name).to eq column1.name
            expect(error.idx).to be_blank
            expect(error.code).to be_blank
            expect(error.full_message).to eq I18n.t("errors.messages.set_filename")
            expect(error.detail).to be_blank
            expect(error.corrector).to be_blank
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "with cms/column/file_upload (video)" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
        let(:file_type) { "video" }
        let!(:column1) do
          create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: file_type)
        end

        let!(:layout) { create_cms_layout cur_site: site }
        let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }
        let(:file1) do
          content_path = "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
          tmp_ss_file(Cms::TempFile, site: site, user: user, node: node, contents: content_path)
        end
        let!(:item) do
          create(
            :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
            column_values: [
              column1.value_type.new(column: column1, file_id: file1.id)
            ]
          )
        end

        it do
          context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq "column-value-#{item.column_values.first.id}"
            expect(error.name).to eq column1.name
            expect(error.idx).to be_blank
            expect(error.code).to be_blank
            message = I18n.t("errors.messages.blank")
            full_message = I18n.t(
              "errors.format",
              attribute: I18n.t("mongoid.attributes.cms/column/value/file_upload.text"),
              message: message)
            expect(error.full_message).to eq full_message
            expect(error.detail).to be_blank
            expect(error.corrector).to be_blank
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "with cms/column/url_field2" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
        let!(:column1) do
          create(:cms_column_url_field2, cur_site: site, cur_form: form)
        end

        let!(:layout) { create_cms_layout cur_site: site }
        let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }
        let!(:item) do
          create(
            :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
            column_values: [
              column1.value_type.new(column: column1, link_url: unique_url, link_label: link_label, link_target: "_blank")
            ]
          )
        end

        context "when link_label is blank" do
          let(:link_label) { "" }

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)
            expect(context.errors).to be_blank
          end
        end

        context "when link_label is 3 length" do
          let(:link_label) { "abc" }

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to eq link_label
              expect(error.full_message).to eq I18n.t("errors.messages.link_text_too_short", count: 4)
              expect(error.detail).to be_blank
              expect(error.corrector).to be_blank
              expect(error.corrector_params).to be_blank
            end
          end
        end

        context "when link_label is 4 length" do
          let(:link_label) { "abcd" }

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)
            expect(context.errors).to be_blank
          end
        end

        context "when link_label contains invalid space" do
          let(:link_label) { "#{unique_id}#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}#{unique_id}" }

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to eq link_label
              expect(error.full_message).to eq I18n.t('errors.messages.check_interword_space')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
              expect(error.corrector).to eq "Cms::SyntaxChecker::InterwordSpaceChecker"
              expect(error.corrector_params).to be_blank
            end
          end
        end
      end

      context "with cms/column/headline" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
        let!(:column1) { create(:cms_column_headline, cur_site: site, cur_form: form, required: "optional") }

        let!(:layout) { create_cms_layout cur_site: site }
        let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }

        context "when text is blank" do
          let(:text) { "" }
          let!(:item) do
            create(
              :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
              column_values: [
                column1.value_type.new(column: column1, head: "h2", text: text)
              ]
            )
          end

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)
            expect(context.errors).to be_blank
          end
        end

        context "when text contains invalid space" do
          let(:text) { "#{unique_id}#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}#{unique_id}" }
          let!(:item) do
            create(
              :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
              column_values: [
                column1.value_type.new(column: column1, head: "h2", text: text)
              ]
            )
          end

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to eq text
              expect(error.full_message).to eq I18n.t('errors.messages.check_interword_space')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
              expect(error.corrector).to eq "Cms::SyntaxChecker::InterwordSpaceChecker"
              expect(error.corrector_params).to be_blank
            end
          end
        end

        context "when the first is h3" do
          let!(:item) do
            create(
              :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
              column_values: [
                column1.value_type.new(column: column1, head: "h3", text: "head-#{unique_id}")
              ]
            )
          end

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to eq "h3"
              expect(error.full_message).to eq I18n.t('errors.messages.invalid_order_of_h')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
              expect(error.corrector).to be_blank
              expect(error.corrector_params).to be_blank
            end
          end
        end

        context "when h1 is following h2" do
          let!(:item) do
            create(
              :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
              column_values: [
                column1.value_type.new(column: column1, head: "h2", text: "head-#{unique_id}"),
                column1.value_type.new(column: column1, head: "h1", text: "head-#{unique_id}"),
              ]
            )
          end

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)
            expect(context.errors).to be_blank
          end
        end

        context "when h3 is following h1" do
          let!(:item) do
            create(
              :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
              column_values: [
                column1.value_type.new(column: column1, head: "h1", text: "head-#{unique_id}"),
                column1.value_type.new(column: column1, head: "h3", text: "head-#{unique_id}"),
              ]
            )
          end

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.second.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to eq "h3"
              expect(error.full_message).to eq I18n.t('errors.messages.invalid_order_of_h')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h')
              expect(error.corrector).to be_blank
              expect(error.corrector_params).to be_blank
            end
          end
        end

        context "when h3 is following h2" do
          let!(:item) do
            create(
              :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
              column_values: [
                column1.value_type.new(column: column1, head: "h2", text: "head-#{unique_id}"),
                column1.value_type.new(column: column1, head: "h3", text: "head-#{unique_id}"),
              ]
            )
          end

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)
            expect(context.errors).to be_blank
          end
        end
      end

      context "with cms/column/list" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
        let!(:column1) { create(:cms_column_list, cur_site: site, cur_form: form) }

        let!(:layout) { create_cms_layout cur_site: site }
        let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }
        let!(:item) do
          create(
            :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
            column_values: [
              column1.value_type.new(column: column1, lists: lists)
            ]
          )
        end

        context "when text contains invalid space" do
          let(:lists) { [ "#{unique_id}#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}#{unique_id}" ] }

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to eq lists[0]
              expect(error.full_message).to eq I18n.t('errors.messages.check_interword_space')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
              expect(error.corrector).to eq "Cms::SyntaxChecker::InterwordSpaceChecker"
              expect(error.corrector_params).to be_blank
            end
          end
        end
      end

      context "with cms/column/table" do
        let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
        let!(:column1) { create(:cms_column_table, cur_site: site, cur_form: form) }

        let!(:layout) { create_cms_layout cur_site: site }
        let!(:node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }
        let!(:item) do
          create(
            :article_page, cur_site: site, cur_user: user, cur_node: node, layout: layout, form: form,
            column_values: [
              column1.value_type.new(column: column1, value: table_html)
            ]
          )
        end

        context "when table caption contains invalid space" do
          let(:caption) { "#{unique_id}#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}#{unique_id}" }
          let(:table_html) do
            <<~HTML
              <table>
                <caption>#{caption}</caption>
                <tbody>
                  <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
                  <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
                  <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
                </tbody>
              </table>
            HTML
          end

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

            expect(context.errors).to have(2).items
            context.errors.first.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to eq caption
              expect(error.full_message).to eq I18n.t('errors.messages.check_interword_space')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.check_interword_space')
              expect(error.corrector).to eq "Cms::SyntaxChecker::InterwordSpaceChecker"
              expect(error.corrector_params).to be_blank
            end
            context.errors.second.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to include("<tr><th></th><td></td></tr>")
              expect(error.full_message).to eq I18n.t('errors.messages.set_th_scope')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.set_th_scope')
              expect(error.corrector).to eq "Cms::SyntaxChecker::TableChecker"
              expect(error.corrector_params).to include(tag: 'th')
            end
          end
        end

        context "when table caption is blank" do
          let(:caption) { "#{unique_id}#{Cms::SyntaxChecker::FULL_WIDTH_SPACE}#{unique_id}" }
          let(:table_html) do
            <<~HTML
              <table>
                <caption></caption>
                <tbody>
                  <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
                  <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
                  <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
                </tbody>
              </table>
            HTML
          end

          it do
            context = described_class.check_page(cur_site: site, cur_user: user, page: item, html: item.render_html)

            expect(context.errors).to have(2).items
            context.errors.first.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to be_present
              expect(error.full_message).to eq I18n.t('errors.messages.set_table_caption')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.set_table_caption')
              expect(error.corrector).to eq "Cms::SyntaxChecker::TableChecker"
              expect(error.corrector_params).to include(tag: 'caption')
            end
            context.errors.second.tap do |error|
              expect(error.id).to eq "column-value-#{item.column_values.first.id}"
              expect(error.name).to eq column1.name
              expect(error.idx).to be_blank
              expect(error.code).to include("<tr><th></th><td></td></tr>")
              expect(error.full_message).to eq I18n.t('errors.messages.set_th_scope')
              expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.set_th_scope')
              expect(error.corrector).to eq "Cms::SyntaxChecker::TableChecker"
              expect(error.corrector_params).to include(tag: 'th')
            end
          end
        end
      end
    end
  end
end
