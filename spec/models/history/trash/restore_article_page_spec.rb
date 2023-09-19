require 'spec_helper'

describe History::Trash, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page, cur_site: site }
  let(:trash_count) { 1 }
  let(:basename) { "#{unique_id}.html" }

  before do
    expect(item.destroy).to be_truthy
    expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound

    trashes = History::Trash.all.to_a
    expect(trashes.length).to eq trash_count
    trashes.first.tap do |trash|
      expect(trash.site_id).to eq site.id
      expect(trash.version).to eq SS.version
      expect(trash.ref_coll).to eq item.collection_name.to_s
      expect(trash.ref_class).to eq item.class.name
      expect(trash.data).to be_present
      expect(trash.data["_id"]).to eq item.id
      expect(trash.state).to be_blank
      expect(trash.action).to eq "save"
    end

    result = trashes.first.restore!(basename: basename)
    expect(result).to be_persisted
    expect(result).to eq item
    expect(result.basename).to eq basename
    expect(result.filename).to end_with basename
    expect(result.state).to eq "closed"

    expect { item.reload }.not_to raise_error
  end

  describe "restore cms/page" do
    context "with basic" do
      let(:name) { "name-#{unique_id}" }
      let(:index_name) { "index_name-#{unique_id}" }
      let(:basename) { "filename-#{unique_id}.html" }
      let(:layout) { create_cms_layout }
      let(:order) { rand(10..20) }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          name: name, index_name: index_name, basename: basename, layout_id: layout.id, order: order
        )
      end

      it do
        expect(item.name).to eq name
        expect(item.index_name).to eq index_name
        expect(item.basename).to eq basename
        expect(item.layout_id).to eq layout.id
        expect(item.order).to eq order
      end
    end

    context "with cms/meta" do
      let(:keywords) { Array.new(2) { "keyword-#{unique_id}" } }
      let(:description) { Array.new(2) { "description-#{unique_id}" }.join("\n") }
      let(:summary_html) { Array.new(2) { "summary_html-#{unique_id}" }.join("\n") }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          keywords: keywords, description: description, summary_html: summary_html
        )
      end

      it do
        expect(item.keywords).to eq keywords
        expect(item.description).to eq description
        expect(item.summary_html).to eq summary_html
      end
    end

    context "with cms/twitter_poster" do
      let(:twitter_auto_post) { %w(expired active).sample }
      # let(:twitter_post_format) { %w(thumb_and_page files_and_page page_only).sample }
      let(:twitter_post_format) { %w(files_and_page page_only).sample }
      let(:twitter_edit_auto_post) { %w(disabled enabled).sample }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          twitter_auto_post: twitter_auto_post, twitter_post_format: twitter_post_format,
          twitter_edit_auto_post: twitter_edit_auto_post
        )
      end

      it do
        expect(item.twitter_auto_post).to eq twitter_auto_post
        expect(item.twitter_post_format).to eq twitter_post_format
        expect(item.twitter_edit_auto_post).to eq twitter_edit_auto_post
      end
    end

    context "with cms/line_poster" do
      let(:line_auto_post) { %w(expired active).sample }
      # let(:line_post_format) { %w(thumb_carousel body_carousel message_only_carousel).sample }
      let(:line_post_format) { %w(body_carousel message_only_carousel).sample }
      let(:line_text_message) { "line_text_message-#{unique_id}" }
      let(:line_edit_auto_post) { %w(disabled enabled).sample }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          line_auto_post: line_auto_post, line_post_format: line_post_format,
          line_text_message: line_text_message, line_edit_auto_post: line_edit_auto_post
        )
      end

      it do
        expect(item.line_auto_post).to eq line_auto_post
        expect(item.line_post_format).to eq line_post_format
        expect(item.line_text_message).to eq line_text_message
        expect(item.line_edit_auto_post).to eq line_edit_auto_post
      end
    end

    context "with cms/thumb" do
      let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
      let!(:file) { tmp_ss_file(site: site, user: user, contents: file_path) }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          thumb_id: file.id
        )
      end
      let(:trash_count) { 2 }

      it do
        expect { file.reload }.not_to raise_error

        expect(item.thumb_id).to eq file.id
        expect(item.thumb).to be_present
      end
    end

    context "with cms/body and cms/file" do
      let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
      let!(:file) { tmp_ss_file(site: site, user: user, contents: file_path) }
      let(:html) do
        [
          "<p>#{unique_id}</p>",
          "<p><a class=\"icon-png attachment\" href=\"#{file.url}\">#{file.humanized_name}</a></p>",
        ].join("\r\n\r\n")
      end
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          html: html, file_ids: [ file.id ]
        )
      end
      let(:trash_count) { 2 }

      it do
        expect { file.reload }.not_to raise_error

        expect(item.file_ids).to eq [ file.id ]
        expect(item.html).to include file.url
      end
    end

    context "with cms/form/page" do
      let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
      let!(:item) do
        node.st_form_ids = [ form.id ]
        node.save!

        item = build(:article_page, cur_user: user, cur_site: site, cur_node: node, form: form)
        item.column_values = [ column_value ]
        item.save!

        expect(item.column_values.count).to eq 1
        item
      end

      context "with Cms::Column::TextField" do
        let!(:column) { create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
        let(:column_value) { column.value_type.new(column: column, value: unique_id) }

        it do
          expect(item.form).to eq form
          expect(item.column_values.length).to eq 1
          item.column_values.first.tap do |column_value1|
            expect(column_value1.class).to eq column_value.class
            expect(column_value1.value).to eq column_value.value
          end
        end
      end

      context "with Cms::Column::TextArea" do
        let!(:column) { create(:cms_column_text_area, cur_site: site, cur_form: form) }
        let(:column_value) { column.value_type.new(column: column, value: unique_id) }

        it do
          expect(item.form).to eq form
          expect(item.column_values.length).to eq 1
          item.column_values.first.tap do |column_value1|
            expect(column_value1.class).to eq column_value.class
            expect(column_value1.value).to eq column_value.value
          end
        end
      end

      context "with Cms::Column::Headline" do
        let!(:column) { create(:cms_column_headline, cur_site: site, cur_form: form) }
        let(:column_value) { column.value_type.new(column: column, head: "h1", text: unique_id) }

        it do
          expect(item.form).to eq form
          expect(item.column_values.length).to eq 1
          item.column_values.first.tap do |column_value1|
            expect(column_value1.class).to eq column_value.class
            expect(column_value1.head).to eq column_value.head
            expect(column_value1.text).to eq column_value.text
          end
        end
      end

      context "with Cms::Column::UrlField2" do
        let!(:column) { create(:cms_column_url_field2, cur_site: site, cur_form: form) }
        let(:column_value) do
          column.value_type.new(column: column, link_label: unique_id, link_url: "/#{unique_id}", link_target: "_blank")
        end

        it do
          expect(item.form).to eq form
          expect(item.column_values.length).to eq 1
          item.column_values.first.tap do |column_value1|
            expect(column_value1.class).to eq column_value.class
            expect(column_value1.link_label).to eq column_value.link_label
            expect(column_value1.link_url).to eq column_value.link_url
            expect(column_value1.link_target).to eq column_value.link_target
          end
        end
      end

      context "with Cms::Column::FileUpload" do
        let!(:column) { create(:cms_column_file_upload, cur_site: site, cur_form: form, file_type: "image") }
        let!(:file) { tmp_ss_file(site: site, user: user, contents: file_path) }
        let(:column_value) { column.value_type.new(column: column, file_label: unique_id, file_id: file.id) }
        let(:trash_count) { 2 }

        it do
          expect(item.form).to eq form
          expect(item.column_values.length).to eq 1
          item.column_values.first.tap do |column_value1|
            expect(column_value1.class).to eq column_value.class
            expect(column_value1.file_label).to eq column_value.file_label
            expect(column_value1.file_id).to eq column_value.file_id
            expect(column_value1.file).to be_present
          end

          expect { file.reload }.not_to raise_error
          file.owner_item_id = item.id
          file.owner_item_type = item.class.name
        end
      end

      context "with Cms::Column::List" do
        let!(:column) { create(:cms_column_list, cur_site: site, cur_form: form, list_type: "ol") }
        let(:column_value) { column.value_type.new(column: column, lists: Array.new(2) { unique_id }) }

        it do
          expect(item.form).to eq form
          expect(item.column_values.length).to eq 1
          item.column_values.first.tap do |column_value1|
            expect(column_value1.class).to eq column_value.class
            expect(column_value1.lists).to eq column_value.lists
          end
        end
      end

      context "with Cms::Column::Table" do
        let!(:column) { create(:cms_column_table, cur_site: site, cur_form: form) }
        let(:table_html) do
          <<~HTML.freeze
            <table>
              <caption>テスト</caption>
              <thead>
                <tr><th scope="col" class="">a</th><th scope="col" class="">b</th><th scope="col" class="">c</th></tr>
              </thead>
              <tbody>
                <tr><td class="">d</td><td class="">d</td><td class="">f</td></tr>
                <tr><td class="">g</td><td class="">h</td><td class="">i</td></tr>
              </tbody>
            </table>
          HTML
        end
        let(:column_value) { column.value_type.new(column: column, value: table_html) }

        it do
          expect(item.form).to eq form
          expect(item.column_values.length).to eq 1
          item.column_values.first.tap do |column_value1|
            expect(column_value1.class).to eq column_value.class
            expect(column_value1.value).to eq column_value.value
          end
        end
      end

      context "with Cms::Column::Free" do
        let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form) }
        let!(:file1) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo1.png") }
        let!(:file2) { tmp_ss_file(site: site, user: user, contents: file_path, basename: "logo2.png") }
        let(:html) do
          <<~HTML.freeze
            <p>#{unique_id}</p>
            <p><a class="icon-png attachment" href="#{file1.url}">#{file1.humanized_name}</a></p>
            <p><a class="icon-png attachment" href="#{file2.url}">#{file2.humanized_name}</a></p>
          HTML
        end
        let(:column_value) { column.value_type.new(column: column, value: html, file_ids: [ file1.id, file2.id ]) }
        let(:trash_count) { 3 }

        it do
          expect(item.form).to eq form
          expect(item.column_values.length).to eq 1
          item.column_values.first.tap do |column_value1|
            expect(column_value1.class).to eq column_value.class
            expect(column_value1.value).to eq column_value.value
            expect(column_value1.file_ids).to have(2).items
          end

          expect { file1.reload }.not_to raise_error
          file1.owner_item_id = item.id
          file1.owner_item_type = item.class.name
          expect { file2.reload }.not_to raise_error
          file2.owner_item_id = item.id
          file2.owner_item_type = item.class.name
        end
      end
    end

    context "with category/category and cms/parent_crumb" do
      let!(:cate) { create :category_node_page, cur_site: site }
      let!(:parent_crumb_urls) { [ cate.url ] }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          category_ids: [ cate.id ], parent_crumb_urls: parent_crumb_urls
        )
      end

      it do
        expect { cate.reload }.not_to raise_error

        expect(item.category_ids).to eq [ cate.id ]
        expect(item.parent_crumb_urls).to eq parent_crumb_urls
      end
    end

    context "with event/date" do
      let!(:event_name) { "event_name-#{unique_id}" }
      let!(:event_dates) { %w(2022/01/12 2022/01/13 2022/01/19 2022/01/20).map { |d| Date.parse(d) } }
      let!(:event_recurr1) do
        { kind: "date", start_at: "2022/01/12", frequency: "daily", until_on: "2022/01/13" }
      end
      let!(:event_recurr2) do
        { kind: "date", start_at: "2022/01/19", frequency: "daily", until_on: "2022/01/20" }
      end
      let!(:event_deadline) { Time.zone.parse("2021/12/15 17:30") }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          event_name: event_name, event_recurrences: [ event_recurr1, event_recurr2 ], event_deadline: event_deadline
        )
      end

      it do
        expect(item.event_name).to eq event_name
        expect(item.event_dates).to eq event_dates
        expect(item.event_recurrences).to have(2).items
        expect(item.event_deadline).to eq event_deadline
      end
    end

    context "with map/page" do
      let!(:map_points) do
        [
          {
            "name" => "name-#{unique_id}", "loc" => [ 137.825391, 36.24383 ],
            "text" => Array.new(2) { "text-#{unique_id}" }.join("\r\n"),
            "image" => "/assets/img/openlayers/marker#{rand(1..9)}.png"
          }
        ]
      end
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          map_points: map_points
        )
      end

      it do
        expect(item.map_points).to have(1).items
        expect(item.map_points[0]["name"]).to eq map_points[0]["name"]
        expect(item.map_points[0]["loc"]).to eq map_points[0]["loc"]
        expect(item.map_points[0]["text"]).to eq map_points[0]["text"]
        expect(item.map_points[0]["image"]).to eq map_points[0]["image"]
      end
    end

    context "with cms/related_page" do
      let!(:related_page1) { create :article_page, cur_site: site, cur_node: node }
      let!(:related_page2) { create :article_page, cur_site: site, cur_node: node }
      let(:related_page_sort) { %w(name filename created).sample }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          related_page_ids: [ related_page1.id, related_page2.id ], related_page_sort: related_page_sort
        )
      end

      it do
        expect(item.related_page_ids).to have(2).items
        expect(item.related_page_ids).to include(related_page1.id, related_page2.id)
        expect(item.related_page_sort).to eq related_page_sort
      end
    end

    context "with contact/page" do
      let!(:contact_state) { %w(show hide).sample }
      let!(:contact_group) { create :cms_group, name: "#{cms_site.groups.first.name}/#{unique_id}" }
      let(:contact_charge) { "contact_charge-#{unique_id}" }
      let(:contact_tel) { "contact_tel-#{unique_id}" }
      let(:contact_fax) { "contact_fax-#{unique_id}" }
      let(:contact_email) { unique_email }
      let(:contact_link_url) { "/#{unique_id}/" }
      let(:contact_link_name) { "contact_link_name-#{unique_id}" }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          contact_state: contact_state, contact_group_id: contact_group.id, contact_charge: contact_charge,
          contact_tel: contact_tel, contact_fax: contact_fax, contact_email: contact_email,
          contact_link_url: contact_link_url, contact_link_name: contact_link_name
        )
      end

      it do
        expect { contact_group.reload }.not_to raise_error

        expect(item.contact_state).to eq contact_state
        expect(item.contact_group_id).to eq contact_group.id
        expect(item.contact_charge).to eq contact_charge
        expect(item.contact_tel).to eq contact_tel
        expect(item.contact_fax).to eq contact_fax
        expect(item.contact_email).to eq contact_email
        expect(item.contact_link_url).to eq contact_link_url
        expect(item.contact_link_name).to eq contact_link_name
      end
    end

    context "with cms/release and cms/release_plan" do
      let!(:released_type) { %w(fixed same_as_updated same_as_created same_as_first_released).sample }
      let!(:released) { Time.zone.now.change(usec: 0) }
      let!(:release_date) { released + rand(1..2).hours }
      let!(:close_date) { release_date + rand(3..5).hours }
      let!(:item) do
        Timecop.freeze(released) do
          create(
            :article_page, cur_user: user, cur_site: site, cur_node: node,
            released_type: released_type, released: released, release_date: release_date, close_date: close_date
          )
        end
      end

      it do
        expect(item.released_type).to eq released_type
        expect(item.released).to eq released
        expect(item.release_date).to eq release_date
        expect(item.close_date).to eq close_date
      end
    end

    context "with cms/group_permission" do
      let!(:group1) { create :cms_group, name: "#{cms_site.groups.first.name}/#{unique_id}" }
      let!(:group2) { create :cms_group, name: "#{cms_site.groups.first.name}/#{unique_id}" }
      let!(:item) do
        create(
          :article_page, cur_user: user, cur_site: site, cur_node: node,
          group_ids: [ group1.id, group2.id ]
        )
      end

      it do
        expect { group1.reload }.not_to raise_error
        expect { group2.reload }.not_to raise_error

        expect(item.group_ids).to have(2).items
        expect(item.group_ids).to include(group1.id, group2.id)
      end
    end
  end
end
