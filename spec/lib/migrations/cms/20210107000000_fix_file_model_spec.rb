require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20200630000001_fix_file_model.rb")

RSpec.describe SS::Migration20200630000001, dbscope: :example do
  let!(:page) { create :cms_page }
  # 正常なページに添付されたファイル
  let!(:file1) { tmp_ss_file(contents: '0123456789', user: cms_user, owner_item: page, model: "cms/page") }
  # 誤ってお問い合わせフォームによって書き換えられたファイル
  let!(:file2) { tmp_ss_file(contents: '0123456789', user: cms_user, owner_item: page, model: "inquiry/answer") }
  # 正常なお問い合わせフォームに添付されたファイル
  let!(:file3) { tmp_ss_file(contents: '0123456789', user: cms_user, owner_item: nil, model: "inquiry/answer") }

  before do
    described_class.new.change
  end

  it do
    file1.reload
    expect(file1.owner_item_id).to eq page.id
    expect(file1.owner_item_type).to eq page.class.name
    expect(file1.model).to eq "cms/page"

    file2.reload
    expect(file2.owner_item_id).to eq page.id
    expect(file2.owner_item_type).to eq page.class.name
    expect(file2.model).to eq "cms/page"

    file3.reload
    expect(file3.owner_item_id).to be_blank
    expect(file3.owner_item_type).to be_blank
    expect(file3.model).to eq "inquiry/answer"
  end
end
