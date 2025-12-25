require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20251210000000_add_setting_type_to_loop_settings.rb")

RSpec.describe SS::Migration20251210000000, dbscope: :example do
  let!(:site) { cms_site }

  let!(:loop_setting_with_snippet_prefix) do
    item = create(:cms_loop_setting,
      site: site,
      name: "スニペット/ページ/ページ名",
      html: "{{ page.name }}",
      html_format: 'liquid',
      state: 'public')
    # loop_html_setting_typeをnilに設定
    item.collection.update_one(
      { "_id" => item._id },
      { "$unset" => { "loop_html_setting_type" => "" } }
    )
    item.reload
    item
  end

  let!(:loop_setting_without_snippet_prefix) do
    item = create(:cms_loop_setting,
      site: site,
      name: "記事/基本記事リスト",
      html: "<div>{{ page.name }}</div>",
      html_format: 'liquid',
      state: 'public')
    # loop_html_setting_typeをnilに設定
    item.collection.update_one(
      { "_id" => item._id },
      { "$unset" => { "loop_html_setting_type" => "" } }
    )
    item.reload
    item
  end

  let!(:loop_setting_with_existing_loop_html_setting_type) do
    create(:cms_loop_setting,
      site: site,
      name: "スニペット/テスト",
      html: "{{ test }}",
      html_format: 'liquid',
      state: 'public',
      loop_html_setting_type: 'snippet')
  end

  before do
    # Check that loop_html_setting_type is actually unset in the database before migration
    raw_doc_snippet_before =
      loop_setting_with_snippet_prefix.collection
        .find("_id" => loop_setting_with_snippet_prefix._id)
        .first
    expect(raw_doc_snippet_before["loop_html_setting_type"]).to be_nil

    raw_doc_template_before =
      loop_setting_without_snippet_prefix.collection
        .find("_id" => loop_setting_without_snippet_prefix._id)
        .first
    expect(raw_doc_template_before["loop_html_setting_type"]).to be_nil

    # Run migration
    described_class.new.change

    # Reload to get updated values
    loop_setting_with_snippet_prefix.reload
    loop_setting_without_snippet_prefix.reload
  end

  it "sets loop_html_setting_type to 'snippet' for items with 'スニペット/' prefix" do
    expect(loop_setting_with_snippet_prefix.loop_html_setting_type).to eq 'snippet'
    expect(loop_setting_with_snippet_prefix.name).to eq "スニペット/ページ/ページ名"
  end

  it "sets loop_html_setting_type to 'template' for items without 'スニペット/' prefix" do
    expect(loop_setting_without_snippet_prefix.loop_html_setting_type).to eq 'template'
    expect(loop_setting_without_snippet_prefix.name).to eq "記事/基本記事リスト"
  end

  it "keeps existing loop_html_setting_type when already present" do
    loop_setting_with_existing_loop_html_setting_type.reload

    expect(loop_setting_with_existing_loop_html_setting_type.loop_html_setting_type).to eq 'snippet'
    expect(loop_setting_with_existing_loop_html_setting_type.name).to eq "スニペット/テスト"
  end

  context "when name does not start with 'スニペット/'" do
    let!(:loop_setting_template) do
      create(:cms_loop_setting,
        site: site,
        name: "記事/カテゴリー付き記事リスト",
        html: "<div>{{ page.name }}</div>",
        html_format: 'liquid',
        state: 'public')
    end

    before do
      loop_setting_template.collection.update_one(
        { "_id" => loop_setting_template._id },
        { "$unset" => { "loop_html_setting_type" => "" } }
      )
      # unset のあとに再度 migration を実行して loop_html_setting_type を補完する
      described_class.new.change
      loop_setting_template.reload
    end

    it "sets loop_html_setting_type to 'template'" do
      expect(loop_setting_template.loop_html_setting_type).to eq 'template'
    end
  end
end
