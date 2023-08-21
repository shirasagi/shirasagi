require 'spec_helper'

describe Sys::SiteCopyJob, dbscope: :example do
  describe "copy form, column and page" do
    let(:site) { cms_site }
    let!(:form1) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:form2) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
    let!(:form1_column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form1, input_type: 'text', order: 10)
    end
    let!(:form1_column2) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form1, file_type: 'image', order: 20)
    end
    let!(:form1_column3) do
      create(:cms_column_free, cur_site: site, cur_form: form1, order: 30)
    end
    let!(:form2_column1) do
      create(:cms_column_text_field, cur_site: site, cur_form: form2, input_type: 'text', order: 10)
    end
    let!(:form2_column2) do
      create(:cms_column_file_upload, cur_site: site, cur_form: form2, file_type: 'image', order: 20)
    end
    let!(:form2_column3) do
      create(:cms_column_free, cur_site: site, cur_form: form2, order: 30)
    end

    let!(:node) { create :article_node_page, cur_site: site }
    let(:page1_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page1_file1_img_tag) { "<img src=\"#{page1_file1.url}\">" }
    let!(:page1) do
      create(
        :article_page, cur_site: site, cur_node: node, basename: "#{unique_id}.html",
        html: unique_id * 5 + "\n" + page1_file1_img_tag, file_ids: [ page1_file1.id ]
      )
    end

    let(:page2_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page2_file2) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page2_file1_img_tag) { "<img src=\"#{page2_file1.url}\">" }
    let(:page2_file2_img_tag) { "<img src=\"#{page2_file2.url}\">" }
    let!(:page2) do
      create(
        :article_page, cur_site: site, cur_node: node, basename: "#{unique_id}.html",
        form: form1, column_values: [
          form1_column1.value_type.new(column: form1_column1, value: unique_id * 6),
          form1_column2.value_type.new(column: form1_column2, file_id: page2_file1.id),
          form1_column3.value_type.new(
            column: form1_column3, value: unique_id * 5 + "\n" + page2_file2_img_tag, file_ids: [ page2_file2.id ]
          )
        ]
      )
    end

    let(:page3_file1) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page3_file2) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page3_file3) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page3_file4) do
      tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", site: site, user: cms_user, model: 'ss/temp_file')
    end
    let(:page3_file1_img_tag) { "<img src=\"#{page3_file1.url}\">" }
    let(:page3_file2_img_tag) { "<img src=\"#{page3_file2.url}\">" }
    let(:page3_file3_img_tag) { "<img src=\"#{page3_file3.url}\">" }
    let(:page3_file4_img_tag) { "<img src=\"#{page3_file4.url}\">" }
    let!(:page3) do
      create(
        :article_page, cur_site: site, cur_node: node, basename: "#{unique_id}.html",
        form: form2,
        column_values: [
          form2_column1.value_type.new(column: form2_column1, order: 0, value: unique_id * 6),
          form2_column1.value_type.new(column: form2_column1, order: 1, value: unique_id * 6),
          form2_column2.value_type.new(column: form2_column2, order: 2, file_id: page3_file1.id),
          form2_column2.value_type.new(column: form2_column2, order: 3, file_id: page3_file2.id),
          form2_column3.value_type.new(
            column: form2_column3, order: 4, value: unique_id * 5 + "\n" + page3_file3_img_tag, file_ids: [ page3_file3.id ]
          ),
          form2_column3.value_type.new(
            column: form2_column3, order: 5, value: unique_id * 5 + "\n" + page3_file4_img_tag, file_ids: [ page3_file4.id ]
          )
        ]
      )
    end

    let(:task) { Sys::SiteCopyTask.new }
    let(:target_host_name) { unique_id }
    let(:target_host_host) { unique_id }
    let(:target_host_domain) { "#{unique_id}.example.jp" }

    before do
      page1_file1.reload
      page2_file1.reload
      page2_file2.reload
      page3_file1.reload
      page3_file2.reload
      page3_file3.reload
      page3_file4.reload
    end

    before do
      task.target_host_name = target_host_name
      task.target_host_host = target_host_host
      task.target_host_domains = [ target_host_domain ]
      task.source_site_id = site.id
      task.copy_contents = 'pages'
      task.save!

      perform_enqueued_jobs do
        Sys::SiteCopyJob.perform_now
      end
    end

    it do
      dest_site = Cms::Site.find_by(host: target_host_host)
      expect(dest_site.name).to eq target_host_name
      expect(dest_site.domains).to include target_host_domain
      expect(dest_site.group_ids).to eq site.group_ids

      dest_form1 = Cms::Form.site(dest_site).find_by(name: form1.name)
      expect(dest_form1.name).to eq form1.name
      expect(dest_form1.html).to eq form1.html
      expect(dest_form1.state).to eq form1.state
      expect(dest_form1.sub_type).to eq form1.sub_type
      expect(dest_form1.columns.count).to eq form1.columns.count

      dest_form1_column1 = dest_form1.columns.find_by(name: form1_column1.name)
      expect(dest_form1_column1.class).to eq form1_column1.class
      expect(dest_form1_column1.name).to eq form1_column1.name
      expect(dest_form1_column1.order).to eq form1_column1.order
      expect(dest_form1_column1.required).to eq form1_column1.required
      expect(dest_form1_column1.tooltips).to eq form1_column1.tooltips
      expect(dest_form1_column1.prefix_label).to eq form1_column1.prefix_label
      expect(dest_form1_column1.postfix_label).to eq form1_column1.postfix_label
      expect(dest_form1_column1.postfix_label).to eq form1_column1.postfix_label
      expect(dest_form1_column1.input_type).to eq form1_column1.input_type

      dest_form1_column2 = dest_form1.columns.find_by(name: form1_column2.name)
      expect(dest_form1_column2.class).to eq form1_column2.class
      expect(dest_form1_column2.name).to eq form1_column2.name
      expect(dest_form1_column2.order).to eq form1_column2.order
      expect(dest_form1_column2.required).to eq form1_column2.required
      expect(dest_form1_column2.tooltips).to eq form1_column2.tooltips
      expect(dest_form1_column2.prefix_label).to eq form1_column2.prefix_label
      expect(dest_form1_column2.postfix_label).to eq form1_column2.postfix_label
      expect(dest_form1_column2.postfix_label).to eq form1_column2.postfix_label
      expect(dest_form1_column2.file_type).to eq form1_column2.file_type
      expect(dest_form1_column2.html_tag).to eq form1_column2.html_tag

      dest_form1_column3 = dest_form1.columns.find_by(name: form1_column3.name)
      expect(dest_form1_column3.class).to eq form1_column3.class
      expect(dest_form1_column3.name).to eq form1_column3.name
      expect(dest_form1_column3.order).to eq form1_column3.order
      expect(dest_form1_column3.required).to eq form1_column3.required
      expect(dest_form1_column3.tooltips).to eq form1_column3.tooltips
      expect(dest_form1_column3.prefix_label).to eq form1_column3.prefix_label
      expect(dest_form1_column3.postfix_label).to eq form1_column3.postfix_label
      expect(dest_form1_column3.postfix_label).to eq form1_column3.postfix_label

      dest_form2 = Cms::Form.site(dest_site).find_by(name: form2.name)
      expect(dest_form2.name).to eq form2.name
      expect(dest_form2.html).to eq form2.html
      expect(dest_form2.state).to eq form2.state
      expect(dest_form2.sub_type).to eq form2.sub_type
      expect(dest_form2.columns.count).to eq form2.columns.count

      dest_form2_column1 = dest_form2.columns.find_by(name: form2_column1.name)
      expect(dest_form2_column1.class).to eq form2_column1.class
      expect(dest_form2_column1.name).to eq form2_column1.name
      expect(dest_form2_column1.order).to eq form2_column1.order
      expect(dest_form2_column1.required).to eq form2_column1.required
      expect(dest_form2_column1.tooltips).to eq form2_column1.tooltips
      expect(dest_form2_column1.prefix_label).to eq form2_column1.prefix_label
      expect(dest_form2_column1.postfix_label).to eq form2_column1.postfix_label
      expect(dest_form2_column1.postfix_label).to eq form2_column1.postfix_label
      expect(dest_form2_column1.input_type).to eq form2_column1.input_type

      dest_form2_column2 = dest_form2.columns.find_by(name: form2_column2.name)
      expect(dest_form2_column2.class).to eq form2_column2.class
      expect(dest_form2_column2.name).to eq form2_column2.name
      expect(dest_form2_column2.order).to eq form2_column2.order
      expect(dest_form2_column2.required).to eq form2_column2.required
      expect(dest_form2_column2.tooltips).to eq form2_column2.tooltips
      expect(dest_form2_column2.prefix_label).to eq form2_column2.prefix_label
      expect(dest_form2_column2.postfix_label).to eq form2_column2.postfix_label
      expect(dest_form2_column2.postfix_label).to eq form2_column2.postfix_label
      expect(dest_form2_column2.file_type).to eq form2_column2.file_type
      expect(dest_form2_column2.html_tag).to eq form2_column2.html_tag

      dest_form2_column3 = dest_form2.columns.find_by(name: form2_column3.name)
      expect(dest_form2_column3.class).to eq form2_column3.class
      expect(dest_form2_column3.name).to eq form2_column3.name
      expect(dest_form2_column3.order).to eq form2_column3.order
      expect(dest_form2_column3.required).to eq form2_column3.required
      expect(dest_form2_column3.tooltips).to eq form2_column3.tooltips
      expect(dest_form2_column3.prefix_label).to eq form2_column3.prefix_label
      expect(dest_form2_column3.postfix_label).to eq form2_column3.postfix_label
      expect(dest_form2_column3.postfix_label).to eq form2_column3.postfix_label

      dest_page1 = Article::Page.site(dest_site).find_by(filename: page1.filename)
      expect(dest_page1.name).to eq page1.name
      expect(dest_page1.filename).to eq page1.filename
      expect(dest_page1.html).not_to eq page1.html
      expect(dest_page1.files.count).to eq page1.files.count
      expect(dest_page1.html).to include(dest_page1.files.first.url)
      expect(dest_page1.files.first.owner_item_id).to eq dest_page1.id

      dest_page2 = Article::Page.site(dest_site).find_by(filename: page2.filename)
      expect(dest_page2.name).to eq page2.name
      expect(dest_page2.filename).to eq page2.filename
      expect(dest_page2.form_id).to eq dest_form1.id
      expect(dest_page2.column_values.count).to eq page2.column_values.count
      dest_page2.column_values.order_by(order: 1).to_a.tap do |dest_column_values|
        column_values = page2.column_values.order_by(order: 1).to_a
        dest_column_values[0].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[0].class
          expect(dest_column_value.name).to eq column_values[0].name
          expect(dest_column_value.order).to eq column_values[0].order
          expect(dest_column_value.value).to eq column_values[0].value
        end

        dest_column_values[1].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[1].class
          expect(dest_column_value.name).to eq column_values[1].name
          expect(dest_column_value.order).to eq column_values[1].order
          expect(dest_column_value.file_id).not_to eq column_values[1].file_id
          expect(dest_column_value.file.name).to eq column_values[1].file.name
          expect(dest_column_value.file.filename).to eq column_values[1].file.filename
          expect(dest_column_value.file.owner_item_id).to eq dest_page2.id
        end

        dest_column_values[2].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[2].class
          expect(dest_column_value.name).to eq column_values[2].name
          expect(dest_column_value.order).to eq column_values[2].order
          expect(dest_column_value.value).not_to eq column_values[2].value
          expect(dest_column_value.value).to include(dest_column_value.files.first.url)
          expect(dest_column_value.file_ids).not_to eq column_values[2].file_ids
          expect(dest_column_value.files.count).to eq column_values[2].files.count
          expect(dest_column_value.files.first.name).to eq column_values[2].files.first.name
          expect(dest_column_value.files.first.filename).to eq column_values[2].files.first.filename
          expect(dest_column_value.files.first.owner_item_id).to eq dest_page2.id
        end
      end

      dest_page3 = Article::Page.site(dest_site).find_by(filename: page3.filename)
      expect(dest_page3.name).to eq page3.name
      expect(dest_page3.filename).to eq page3.filename
      expect(dest_page3.form_id).to eq dest_form2.id
      expect(dest_page3.column_values.count).to eq page3.column_values.count
      dest_page3.column_values.order_by(order: 1).to_a.tap do |dest_column_values|
        column_values = page3.column_values.order_by(order: 1).to_a
        dest_column_values[0].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[0].class
          expect(dest_column_value.name).to eq column_values[0].name
          expect(dest_column_value.order).to eq column_values[0].order
          expect(dest_column_value.value).to eq column_values[0].value
        end

        dest_column_values[1].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[1].class
          expect(dest_column_value.name).to eq column_values[1].name
          expect(dest_column_value.order).to eq column_values[1].order
          expect(dest_column_value.value).to eq column_values[1].value
        end

        dest_column_values[2].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[2].class
          expect(dest_column_value.name).to eq column_values[2].name
          expect(dest_column_value.order).to eq column_values[2].order
          expect(dest_column_value.file_id).not_to eq column_values[2].file_id
          expect(dest_column_value.file.name).to eq column_values[2].file.name
          expect(dest_column_value.file.filename).to eq column_values[2].file.filename
          expect(dest_column_value.file.owner_item_id).to eq dest_page3.id
        end

        dest_column_values[3].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[3].class
          expect(dest_column_value.name).to eq column_values[3].name
          expect(dest_column_value.order).to eq column_values[3].order
          expect(dest_column_value.file_id).not_to eq column_values[3].file_id
          expect(dest_column_value.file.name).to eq column_values[3].file.name
          expect(dest_column_value.file.filename).to eq column_values[3].file.filename
          expect(dest_column_value.file.owner_item_id).to eq dest_page3.id
        end

        dest_column_values[4].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[4].class
          expect(dest_column_value.name).to eq column_values[4].name
          expect(dest_column_value.order).to eq column_values[4].order
          expect(dest_column_value.value).not_to eq column_values[4].value
          expect(dest_column_value.value).to include(dest_column_value.files.first.url)
          expect(dest_column_value.file_ids).not_to eq column_values[4].file_ids
          expect(dest_column_value.files.count).to eq column_values[4].files.count
          expect(dest_column_value.files.first.name).to eq column_values[4].files.first.name
          expect(dest_column_value.files.first.filename).to eq column_values[4].files.first.filename
          expect(dest_column_value.files.first.owner_item_id).to eq dest_page3.id
        end

        dest_column_values[5].tap do |dest_column_value|
          expect(dest_column_value.class).to eq column_values[5].class
          expect(dest_column_value.name).to eq column_values[5].name
          expect(dest_column_value.order).to eq column_values[5].order
          expect(dest_column_value.value).not_to eq column_values[5].value
          expect(dest_column_value.value).to include(dest_column_value.files.first.url)
          expect(dest_column_value.file_ids).not_to eq column_values[5].file_ids
          expect(dest_column_value.files.count).to eq column_values[5].files.count
          expect(dest_column_value.files.first.name).to eq column_values[5].files.first.name
          expect(dest_column_value.files.first.filename).to eq column_values[5].files.first.filename
          expect(dest_column_value.files.first.owner_item_id).to eq dest_page3.id
        end
      end
    end
  end
end
