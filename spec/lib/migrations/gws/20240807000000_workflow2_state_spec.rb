require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20240807000000_workflow2_state.rb")

RSpec.describe SS::Migration20240807000000, dbscope: :example do
  let!(:site1) { create :gws_group }
  let!(:site2) { create :gws_group }
  let!(:workflow2_form) { create(:gws_workflow2_form_application, state: "public") }
  let!(:workflow2_column1) { create(:gws_column_text_field, form: workflow2_form, input_type: "text") }
  let!(:workflow2_file) do
    create :gws_workflow2_file, form: workflow2_form, column_values: [ workflow2_column1.serialize_value(unique_id) ]
  end

  before do
    # site1: workflow を利用中
    site1.unset(:menu_workflow2_state)
    site1.update(menu_workflow_state: 'show')

    # 新しいプログラムを反映直後、メニューの表示状態は以下のようになっている
    expect(site1.menu_workflow_visible?).to be_truthy
    expect(site1.menu_workflow2_visible?).to be_truthy

    # site2: workflow を利用していない
    site2.unset(:menu_workflow2_state)
    site2.update(menu_workflow_state: 'hide')

    # 新しいプログラムを反映直後、メニューの表示状態は以下のようになっている
    expect(site2.menu_workflow_visible?).to be_falsey
    expect(site2.menu_workflow2_visible?).to be_truthy

    described_class.new.change
  end

  it do
    Gws::Group.find(site1.id).tap do |site|
      expect(site.menu_workflow_visible?).to be_truthy
      expect(site.menu_workflow2_visible?).to be_falsey
    end
    Gws::Group.find(site2.id).tap do |site|
      expect(site.menu_workflow_visible?).to be_falsey
      expect(site.menu_workflow2_visible?).to be_falsey
    end
  end
end
