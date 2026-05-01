require 'spec_helper'

describe Cms::SyntaxChecker::Column::FilesAltPresenceChecker, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:column) { create(:cms_column_multiple_images_upload, cur_form: form, order: 1) }
  let!(:image1) do
    tmp_ss_file(
      Cms::File,
      contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
      site: site, user: cms_user, model: Cms::File::FILE_MODEL
    )
  end
  let!(:image2) do
    tmp_ss_file(
      Cms::File,
      contents: "#{Rails.root}/spec/fixtures/webapi/replace.png",
      site: site, user: cms_user, model: Cms::File::FILE_MODEL
    )
  end

  describe "#check via Cms::SyntaxChecker.check_page" do
    context "when every attached file has an alt text" do
      let!(:page_obj) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form, state: 'public',
          column_values: [
            column.value_type.new(
              column: column,
              file_ids: [image1.id.to_s, image2.id.to_s],
              file_labels: { image1.id.to_s => "first-alt", image2.id.to_s => "second-alt" }
            )
          ]
        )
      end

      it "does not add a missing-alt error for any file" do
        page_obj.reload
        context = Cms::SyntaxChecker.check_page(cur_site: site, cur_user: cms_user, page: page_obj)
        messages = context.errors.map(&:error)

        page_obj.column_values.first.files.each do |file|
          expected = I18n.t("errors.messages.blank_file_label", filename: file.name)
          expect(messages).not_to include(expected)
        end
      end
    end

    context "when an attached file has no alt text" do
      let!(:page_obj) do
        create(
          :article_page, cur_site: site, cur_node: node, form: form, state: 'public',
          column_values: [
            column.value_type.new(
              column: column,
              file_ids: [image1.id.to_s, image2.id.to_s],
              file_labels: { image1.id.to_s => "first-alt" }
            )
          ]
        )
      end

      it "adds a missing-alt error for only the file without an alt text" do
        page_obj.reload
        value = page_obj.column_values.first
        labelled_file = value.files.find { |f| f.id.to_s == value.file_labels.keys.first }
        unlabelled_file = value.files.find { |f| f.id.to_s != value.file_labels.keys.first }

        context = Cms::SyntaxChecker.check_page(cur_site: site, cur_user: cms_user, page: page_obj)
        messages = context.errors.map(&:error)

        expect(messages).to include(
          I18n.t("errors.messages.blank_file_label", filename: unlabelled_file.name)
        )
        expect(messages).not_to include(
          I18n.t("errors.messages.blank_file_label", filename: labelled_file.name)
        )
      end
    end
  end
end
