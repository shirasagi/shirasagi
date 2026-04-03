require 'spec_helper'

describe Gws::Notice::FolderExporter, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let(:truncate) { [ true, false ].sample }
  let(:encoding) { "UTF-8" }
  let(:criteria) { [ item ] }
  let(:csv_rows) do
    I18n.with_locale(I18n.default_locale) do
      described_class.new(site: site, user: user, criteria: criteria, truncate: truncate)
                     .then { _1.enum_csv(encoding: encoding, model: Gws::Notice::Folder) }
                     .then { _1.to_a }
    end
  end

  context "basic" do
    let(:item) do
      build(
        :gws_notice_folder, cur_site: site, cur_user: user, name: "name-#{unique_id}",
        depth: rand(10..20), order: rand(20..30), state: %w(public closed))
    end

    it do
      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(StringIO.new(csv_rows.join)) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          expect(csv_table[0][Gws::Notice::Folder.t(:name)]).to eq item.name
          expect(csv_table[0][Gws::Notice::Folder.t(:depth)]).to eq item.depth.to_s
          expect(csv_table[0][Gws::Notice::Folder.t(:order)]).to eq item.order.to_s
          expect(csv_table[0][Gws::Notice::Folder.t(:state)]).to eq item.label(:state)
        end
      end
    end
  end

  context "member" do
    let!(:custom_group1) { create :gws_custom_group, cur_site: site }
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:user1) { create :gws_user, cur_site: site, group_ids: [ group1.id ] }
    let(:item) do
      build(
        :gws_notice_folder, cur_site: site, cur_user: user,
        member_custom_group_ids: [ custom_group1.id ], member_group_ids: [ group1.id ], member_ids: [ user1.id ])
    end

    it do
      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(StringIO.new(csv_rows.join)) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          expect(csv_table[0][Gws::Notice::Folder.t(:member_custom_group_ids)]).to eq custom_group1.name
          expect(csv_table[0][Gws::Notice::Folder.t(:member_group_ids)]).to eq group1.name
          expect(csv_table[0][Gws::Notice::Folder.t(:member_ids)]).to eq user1.uid
        end
      end
    end
  end

  context "readable_setting" do
    let!(:custom_group1) { create :gws_custom_group, cur_site: site }
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:user1) { create :gws_user, cur_site: site, group_ids: [ group1.id ] }
    let(:item) do
      build(
        :gws_notice_folder, cur_site: site, cur_user: user, readable_setting_range: %w(public select private),
        readable_custom_group_ids: [ custom_group1.id ], readable_group_ids: [ group1.id ], readable_member_ids: [ user1.id ])
    end

    it do
      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(StringIO.new(csv_rows.join)) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          expect(csv_table[0][Gws::Notice::Folder.t(:readable_setting_range)]).to eq item.label(:readable_setting_range)
          expect(csv_table[0][Gws::Notice::Folder.t(:readable_custom_group_ids)]).to eq custom_group1.name
          expect(csv_table[0][Gws::Notice::Folder.t(:readable_group_ids)]).to eq group1.name
          expect(csv_table[0][Gws::Notice::Folder.t(:readable_member_ids)]).to eq user1.uid
        end
      end
    end
  end

  context "group_permission" do
    let!(:custom_group1) { create :gws_custom_group, cur_site: site }
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:user1) { create :gws_user, cur_site: site, group_ids: [ group1.id ] }
    let(:item) do
      build(
        :gws_notice_folder, cur_site: site, cur_user: user,
        custom_group_ids: [ custom_group1.id ], group_ids: [ group1.id ], user_ids: [ user1.id ])
    end

    it do
      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(StringIO.new(csv_rows.join)) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          if Gws::Notice::Folder.permission_included_custom_groups?
            expect(csv_table[0][Gws::Notice::Folder.t(:custom_group_ids)]).to eq custom_group1.name
          end
          expect(csv_table[0][Gws::Notice::Folder.t(:group_ids)]).to eq group1.name
          expect(csv_table[0][Gws::Notice::Folder.t(:user_ids)]).to eq user1.uid
        end
      end
    end
  end
end
