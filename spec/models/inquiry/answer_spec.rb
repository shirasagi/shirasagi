require 'spec_helper'

describe Inquiry::Answer, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :inquiry_node_form, cur_site: site }

  before do
    node.columns.create! attributes_for(:inquiry_column_name).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_optional).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_email).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_radio).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_select).reverse_merge({cur_site: site})
    node.columns.create! attributes_for(:inquiry_column_check).reverse_merge({cur_site: site})
    node.reload
  end

  let(:name_column) { node.columns[0] }
  let(:email_column) { node.columns[2] }
  let(:radio_column) { node.columns[3] }
  let(:select_column) { node.columns[4] }
  let(:check_column) { node.columns[5] }

  let(:remote_addr) { "X.X.X.X" }
  let(:user_agent) { unique_id }
  subject { Inquiry::Answer.new(cur_site: site, cur_node: node, remote_addr: remote_addr, user_agent: user_agent) }

  describe "create answer" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:email_confirmation) { email }
    let(:radio) { radio_column.select_options.sample }
    let(:select) { select_column.select_options.sample }
    let(:check) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email_confirmation]
      data[radio_column.id] = [radio]
      data[select_column.id] = [select]
      data[check_column.id] = [check]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      puts subject.errors.full_messages
      expect(subject.errors.blank?).to be_truthy
      expect(subject.data.count).to eq 5
      expect(subject.data[0].value).to eq name
      expect(subject.data[1].value).to eq email
      expect(subject.data[2].value).to eq radio
      expect(subject.data[3].value).to eq select
      expect(subject.data[4].value).to eq check.values.join("\n")
    end
  end

  describe "without name which is required" do
    let(:email) { "#{unique_id}@example.jp" }
    let(:email_confirmation) { email }

    let(:data) do
      data = {}
      data[email_column.id] = [email, email_confirmation]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      expect(subject.errors.blank?).to be_falsey
      expect(subject.errors.full_messages).to include("#{name_column.name}を入力してください。")
    end
  end

  describe "without email which is required" do
    let(:name) { unique_id }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      expect(subject.errors.blank?).to be_falsey
      expect(subject.errors.full_messages).to include("#{email_column.name}を入力してください。")
    end
  end

  describe "without email confirmation" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      expect(subject.errors.blank?).to be_falsey
      expect(subject.errors.full_messages).to include("#{email_column.name}が一致しません。")
    end
  end

  describe "with wrong email confirmation" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:email_confirmation) { "#{unique_id}@example.jp" }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email_confirmation]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      expect(subject.errors.blank?).to be_falsey
      expect(subject.errors.full_messages).to include("#{email_column.name}が一致しません。")
    end
  end

  describe "with invalid email" do
    let(:name) { unique_id }
    let(:email) { "<script>alert(\"hello\");</script>" }
    let(:email_confirmation) { email }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email_confirmation]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      expect(subject.errors.blank?).to be_falsey
      expect(subject.errors.full_messages).to include("#{email_column.name}は有効な電子メールアドレスを入力してください。")
    end
  end

  describe "with invalid radio" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:email_confirmation) { email }
    let(:radio) { unique_id }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email_confirmation]
      data[radio_column.id] = [radio]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      expect(subject.errors.blank?).to be_falsey
      expect(subject.errors.full_messages).to include("#{radio_column.name}は不正な値です。")
    end
  end

  describe "with invalid select" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:email_confirmation) { email }
    let(:select) { unique_id }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email_confirmation]
      data[select_column.id] = [select]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      expect(subject.errors.blank?).to be_falsey
      expect(subject.errors.full_messages).to include("#{select_column.name}は不正な値です。")
    end
  end

  describe "with invalid check" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:email_confirmation) { email }
    let(:check) { { (check_column.select_options.count + 1).to_s => unique_id } }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email_confirmation]
      data[check_column.id] = [check]
      data
    end

    before do
      subject.set_data(data)
      subject.save
    end

    it do
      expect(subject.errors.blank?).to be_falsey
      expect(subject.errors.full_messages).to include("#{check_column.name}は不正な値です。")
    end
  end

  describe "with page's source_url" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:email_confirmation) { email }
    let(:radio) { radio_column.select_options.sample }
    let(:select) { select_column.select_options.sample }
    let(:check) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
    let(:page) { create :cms_page, cur_site: site }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email_confirmation]
      data[radio_column.id] = [radio]
      data[select_column.id] = [select]
      data[check_column.id] = [check]
      data
    end

    before do
      subject.source_url = page.url
      subject.set_data(data)
      subject.save
    end

    its(:source_name) { is_expected.to eq page.name }
    its(:source_full_url) { is_expected.to eq page.full_url }
    its(:source_content) { expect(subject.source_content.becomes_with_route).to eq page }
  end

  describe "with node's source_url" do
    let(:name) { unique_id }
    let(:email) { "#{unique_id}@example.jp" }
    let(:email_confirmation) { email }
    let(:radio) { radio_column.select_options.sample }
    let(:select) { select_column.select_options.sample }
    let(:check) { Hash[check_column.select_options.map.with_index { |val, i| [i.to_s, val] }.sample(2)] }
    let(:node1) { create :category_node_page, cur_site: site }

    let(:data) do
      data = {}
      data[name_column.id] = [name]
      data[email_column.id] = [email, email_confirmation]
      data[radio_column.id] = [radio]
      data[select_column.id] = [select]
      data[check_column.id] = [check]
      data
    end

    before do
      subject.source_url = node1.url
      subject.set_data(data)
      subject.save
    end

    its(:source_name) { is_expected.to eq node1.name }
    its(:source_full_url) { is_expected.to eq node1.full_url }
    its(:source_content) { expect(subject.source_content.becomes_with_route).to eq node1 }
  end
end
