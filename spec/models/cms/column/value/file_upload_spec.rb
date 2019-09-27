require 'spec_helper'

describe Cms::Column::Value::FileUpload, type: :model, dbscope: :example do
  describe "what cms/column/value/file_upload exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:file) do
      SS::File.create_empty!(
        site_id: cms_site.id, cur_user: cms_user, model: "article/page",
        name: "#{unique_id}.png", filename: "#{unique_id}.png", content_type: "image/png"
      ) do |file|
        ::FileUtils.cp("#{Rails.root}/spec/fixtures/ss/logo.png", file.path)
      end
    end
    let(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(
            column: column1, html_tag: column1.html_tag, file: file,
            file_label: "<p>#{unique_id}</p><script>#{unique_id}</script>",
            text: Array.new(2) { "<p>#{unique_id}</p><script>#{unique_id}</script>" }.join("\n"),
            image_html_type: "thumb", link_url: "http://#{unique_id}.example.jp/"
          )
        ]
      )
    end
    let(:value) { page.column_values.first }
    let(:assigns) { {} }
    let(:registers) { { cur_site: cms_site } }
    subject { value.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    context "with file_type 'image'" do
      let(:column1) { create(:cms_column_file_upload, cur_form: form, order: 1, file_type: 'image', html_tag: "a+img") }

      it do
        expect(subject.name).to eq column1.name
        expect(subject.alignment).to eq value.alignment
        expect(subject.type).to eq described_class.name
        expect(subject.file_type).to eq column1.file_type
        expect(subject.file.name).to eq file.name
        expect(subject.file_label).to eq value.file_label
        expect(subject.text).to eq value.text
        expect(subject.image_html_type).to eq value.image_html_type
        expect(subject.link_url).to eq value.link_url

        html = "<img alt=\"#{value.file_label.gsub(/<.*?>/, "")}\" src=\"#{file.thumb_url}\" />"
        html = "<a href=\"#{file.url}\">#{html}</a>"
        expect(subject.html).to eq html
      end
    end

    context "with file_type 'video'" do
      let!(:column1) { create(:cms_column_file_upload, cur_form: form, order: 1, file_type: 'video', html_tag: "a+img") }

      it do
        expect(subject.name).to eq column1.name
        expect(subject.alignment).to eq value.alignment
        expect(subject.type).to eq described_class.name
        expect(subject.file_type).to eq column1.file_type
        expect(subject.file.name).to eq file.name
        expect(subject.file_label).to eq value.file_label
        expect(subject.text).to eq value.text
        expect(subject.image_html_type).to eq value.image_html_type
        expect(subject.link_url).to eq value.link_url

        html1 = "<video controls=\"controls\" src=\"#{file.url}\"></video>"
        html2 = "<div>#{value.text.gsub(/<\/?script>/, "").gsub("\n", "<br>")}</div>"
        expect(subject.html).to eq "<div>#{html1}#{html2}</div>"
      end
    end

    context "with file_type 'attachment'" do
      let!(:column1) { create(:cms_column_file_upload, cur_form: form, order: 1, file_type: 'attachment', html_tag: "a+img") }

      it do
        expect(subject.name).to eq column1.name
        expect(subject.alignment).to eq value.alignment
        expect(subject.type).to eq described_class.name
        expect(subject.file_type).to eq column1.file_type
        expect(subject.file.name).to eq file.name
        expect(subject.file_label).to eq value.file_label
        expect(subject.text).to eq value.text
        expect(subject.image_html_type).to eq value.image_html_type
        expect(subject.link_url).to eq value.link_url

        html = CGI.escapeHTML(value.file_label.gsub(/<\/?script>/, ""))
        html = "<a href=\"#{file.url}\">#{html} (#{file.extname.upcase} #{file.size.to_s(:human_size)})</a>"
        expect(subject.html).to eq html
      end
    end

    context "with file_type 'banner'" do
      let!(:column1) { create(:cms_column_file_upload, cur_form: form, order: 1, file_type: 'banner', html_tag: "a+img") }

      it do
        expect(subject.name).to eq column1.name
        expect(subject.alignment).to eq value.alignment
        expect(subject.type).to eq described_class.name
        expect(subject.file_type).to eq column1.file_type
        expect(subject.file.name).to eq file.name
        expect(subject.file_label).to eq value.file_label
        expect(subject.text).to eq value.text
        expect(subject.image_html_type).to eq value.image_html_type
        expect(subject.link_url).to eq value.link_url

        html = "<img alt=\"#{value.file_label.gsub(/<.*?>/, "")}\" src=\"#{file.url}\" />"
        html = "<a href=\"#{value.link_url}\">#{html}</a>"
        expect(subject.html).to eq html
      end
    end
  end
end
