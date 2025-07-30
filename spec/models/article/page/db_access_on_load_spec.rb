require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }
  let!(:file) { tmp_ss_file(site: cms_site, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }
  let!(:selectable_page1) { create :article_page, cur_node: node, state: 'public' }
  let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
  let!(:column1) { create(:cms_column_text_field, cur_form: form, order: 1, input_type: 'text') }
  let!(:column2) { create(:cms_column_date_field, cur_form: form, order: 2) }
  let!(:column3) { create(:cms_column_url_field2, cur_form: form, order: 3, html_tag: '') }
  let!(:column4) { create(:cms_column_text_area, cur_form: form, order: 4) }
  let!(:column5) { create(:cms_column_select, cur_form: form, order: 5) }
  let!(:column6) { create(:cms_column_radio_button, cur_form: form, order: 6) }
  let!(:column7) { create(:cms_column_check_box, cur_form: form, order: 7) }
  let!(:column8) { create(:cms_column_file_upload, cur_form: form, order: 8, file_type: "image") }
  let!(:column9) { create(:cms_column_select_page, cur_form: form, order: 9, node_ids: [node.id]) }
  let!(:page) do
    create(
      :article_page, cur_node: node, form: form,
      column_values: [
        column1.value_type.new(column: column1, value: unique_id * 2),
        column2.value_type.new(column: column2, date: "#{rand(2000..2050)}/01/01"),
        column3.value_type.new(column: column3, link_url: unique_url, link_label: "Link To"),
        column4.value_type.new(column: column4, value: Array.new(2) { unique_id }.join("\n")),
        column5.value_type.new(column: column5, value: column5.select_options.sample),
        column6.value_type.new(column: column6, value: column6.select_options.sample),
        column7.value_type.new(column: column7, values: column7.select_options.sample(2)),
        column8.value_type.new(
          column: column8, html_tag: column8.html_tag, file: file,
          file_label: "<p>#{unique_id}</p><script>#{unique_id}</script>",
          text: Array.new(2) { "<p>#{unique_id}</p><script>#{unique_id}</script>" }.join("\n"),
          image_html_type: "thumb", link_url: "http://#{unique_id}.example.jp/ "
        ),
        column9.value_type.new(column: column9, page_id: selectable_page1.id)
      ]
    )
  end

  before do
    @subscriber = Class.new do
      cattr_accessor :db_access_count, :db_success_count, :db_failed_count, instance_accessor: false, default: 0

      def self.started(event)
        self.db_access_count += 1
      end

      def self.succeeded(event)
        self.db_success_count += 1
      end

      def self.failed(event)
        self.db_failed_count += 1
      end

      def self.reset_counter
        self.db_access_count = 0
        self.db_success_count = 0
        self.db_failed_count = 0
      end
    end
    Mongo::Monitoring::Global.subscribe(Mongo::Monitoring::COMMAND, @subscriber)
    Mongoid::Clients.clients.each { |_key, client| client.subscribe(Mongo::Monitoring::COMMAND, @subscriber) }
  end

  after do
    ::ActiveSupport::Notifications.unsubscribe(@subscriber)
    Mongoid::Clients.clients.each { |_key, client| client.unsubscribe(Mongo::Monitoring::COMMAND, @subscriber) }
  end

  it do
    raw_bson = Cms::Page.find(page.id).attributes.to_bson.to_s
    attributes = Hash.from_bson(BSON::ByteBuffer.new(raw_bson))

    # ロード時にデータベースアクセスが発生しないことを確認する。
    @subscriber.reset_counter
    Mongoid::Factory.from_db(Cms::Page, attributes)
    expect(@subscriber.db_access_count).to eq 0
  end
end
