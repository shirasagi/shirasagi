require 'spec_helper'

describe Gws::Survey::FileEnumerator, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user0) { gws_user }
  let!(:user1) { create(:gws_user, group_ids: user0.group_ids, gws_role_ids: user0.gws_role_ids) }
  let!(:cate) { create(:gws_survey_category, cur_site: site) }

  let!(:form) do
    create(
      :gws_survey_form, cur_site: site, state: "public", anonymous_state: "disabled", file_state: "public",
      readable_setting_range: "public", readable_group_ids: [], readable_member_ids: [])
  end
  let!(:column1) { create :gws_column_check_box, cur_site: site, form: form, order: 10, required: "required" }
  let(:column1_value) { column1.select_options.sample }
  let!(:column2) { create :gws_column_check_box, cur_site: site, form: form, order: 20, required: "required" }
  let(:column2_value) { column2.select_options.sample }
  let!(:file1) do
    Gws::Survey::File.create(
      cur_site: site, site: site, cur_user: user1, cur_form: form, form: form,
      name: unique_id, anonymous_state: form.anonymous_state,
      column_values: [ column1.serialize_value(column1_value), column2.serialize_value(column2_value) ]
    )
  end

  context "when order by id and order by order are same" do
    it do
      enum = Gws::Survey::FileEnumerator.new(form.files, OpenStruct.new(cur_site: site, cur_form: form, encoding: "UTF-8"))
      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(StringIO.new(enum.to_a.join)) do |csv|
          table = csv.read
          expect(table.length).to eq 1
          table[0].tap do |row|
            expect(row[Gws::Survey::File.t(:updated)]).to eq I18n.l(file1.updated, format: :csv)
            expect(row[Gws::User.t(:name)]).to eq user1.name
            (user1.organization_uid.presence || user1.uid).tap do |organization_uid|
              expect(row[Gws::User.t(:organization_uid)]).to eq organization_uid
            end
            expect(row[column1.name]).to eq [ column1.prefix_label, column1_value, column1.postfix_label ].join
            expect(row[column2.name]).to eq [ column2.prefix_label, column2_value, column2.postfix_label ].join
          end
        end
      end
    end

    context "when order by id and order by order are different" do
      before do
        column1.set(order: 200)
        column2.set(order: 100)
      end

      it do
        enum = Gws::Survey::FileEnumerator.new(form.files, OpenStruct.new(cur_site: site, cur_form: form, encoding: "UTF-8"))
        I18n.with_locale(I18n.default_locale) do
          SS::Csv.open(StringIO.new(enum.to_a.join)) do |csv|
            table = csv.read
            expect(table.length).to eq 1
            table[0].tap do |row|
              expect(row[Gws::Survey::File.t(:updated)]).to eq I18n.l(file1.updated, format: :csv)
              expect(row[Gws::User.t(:name)]).to eq user1.name
              (user1.organization_uid.presence || user1.uid).tap do |organization_uid|
                expect(row[Gws::User.t(:organization_uid)]).to eq organization_uid
              end
              expect(row[column2.name]).to eq [ column2.prefix_label, column2_value, column2.postfix_label ].join
              expect(row[column1.name]).to eq [ column1.prefix_label, column1_value, column1.postfix_label ].join
            end
          end
        end
      end
    end
  end
end
