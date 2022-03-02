require 'spec_helper'

describe Gws::UserCsv::Importer, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let!(:title) { create(:gws_user_title, code: 'E100', name: '社長') }
  let!(:occupation) { create(:gws_user_occupation, code: 'B133', name: '看護師') }
  let!(:sys_role1) { create(:sys_role_general, name: "一般ユーザー") }

  context 'with no forms' do
    let(:file) { "#{Rails.root}/spec/fixtures/gws/user/gws_users.csv" }

    it do
      item = nil
      Fs::UploadedFile.create_from_file(file) do |f|
        item = Gws::UserCsv::Importer.new(cur_site: site, in_file: f)
        item.import
      end

      expect(item.imported).to eq 1
      Gws::User.unscoped.find_by(uid: 'user4').tap do |user|
        expect(user.name).to eq '一般ユーザー4'
        expect(user.kana).to eq 'ユーザー4'
        expect(user.organization_uid).to eq 'user4'
        expect(user.email).to eq 'user4@example.jp'
        expect(user.password).to eq SS::Crypt.crypt('pass')
        expect(user.tel).to eq '000-0000-0001'
        expect(user.tel_ext).to eq '1000'
        expect(user.title_ids).to eq [title.id]
        expect(user.occupation_ids).to eq [occupation.id]
        expect(user.type).to eq 'sns'
        expect(user.account_start_date).to eq Time.zone.parse('2017/11/1  12:02:00')
        expect(user.account_expiration_date).to eq Time.zone.parse('2017/11/2  13:52:00')
        expect(user.initial_password_warning).to be_nil
        expect(user.session_lifetime).to eq 300
        expect(user.organization_id).to eq Gws::Group.find_by(name: 'シラサギ市').id
        expect(user.group_ids).to eq [Gws::Group.find_by(name: 'シラサギ市/企画政策部/政策課').id]
        expect(user.gws_main_group_ids).to eq({'1' => Gws::Group.find_by(name: 'シラサギ市/企画政策部/政策課').id})
        expect(user.remark).to eq 'テキスト'
        expect(user.ldap_dn).to eq 'cn=Manager,dc=city,dc=shirasagi,dc=jp'
        expect(user.gws_role_ids).to eq []
        expect(user.sys_role_ids).to eq [sys_role1.id]
      end
    end
  end

  context 'with form' do
    let(:file) { "#{Rails.root}/spec/fixtures/gws/user/gws_users002.csv" }
    let!(:form) { Gws::UserForm.create(cur_site: site, state: 'public') }
    let!(:column1) do
      Gws::Column::TextField.create!(
        cur_site: site, cur_form: form, name: '一行テキスト', order: 10, required: 'optional',
        input_type: 'text'
      )
    end
    let!(:column2) do
      Gws::Column::TextArea.create!(
        cur_site: site, cur_form: form, name: '複数行テキスト', order: 20, required: 'optional'
      )
    end
    let!(:column3) do
      Gws::Column::DateField.create!(
        cur_site: site, cur_form: form, name: '日付', order: 30, required: 'optional'
      )
    end
    let!(:column4) do
      Gws::Column::CheckBox.create!(
        cur_site: site, cur_form: form, name: 'チェック', order: 40, required: 'optional',
        select_options: "選択1\n選択2\n選択3"
      )
    end
    let!(:column5) do
      Gws::Column::NumberField.create!(
        cur_site: site, cur_form: form, name: '数値', order: 50, required: 'optional',
        minus_type: 'normal'
      )
    end

    it do
      item = nil
      Fs::UploadedFile.create_from_file(file) do |f|
        item = Gws::UserCsv::Importer.new(cur_site: site, in_file: f)
        item.import
      end

      expect(item.imported).to eq 1
      Gws::User.unscoped.find_by(uid: 'user4').tap do |user|
        expect(user.name).to eq '一般ユーザー4'
        expect(user.kana).to eq 'ユーザー4'
        expect(user.organization_uid).to eq 'user4'

        Gws::UserFormData.site(site).form(form).user(user).first.tap do |form_data|
          expect(form_data.column_values.count).to eq 5
          form_data.column_values.find_by(column_id: column1.id).tap do |column_value|
            expect(column_value.value).to eq '一行テキスト'
          end
          form_data.column_values.find_by(column_id: column2.id).tap do |column_value|
            expect(column_value.value).to eq '複数行テキスト'
          end
          form_data.column_values.find_by(column_id: column3.id).tap do |column_value|
            expect(column_value.date).to eq Time.zone.parse('2017/11/1')
          end
          form_data.column_values.find_by(column_id: column4.id).tap do |column_value|
            expect(column_value.values).to eq %w(選択1 選択3)
          end
          form_data.column_values.find_by(column_id: column5.id).tap do |column_value|
            expect(column_value.decimal).to eq 5381
          end
        end
      end
    end
  end
end
