require 'spec_helper'

describe Gws::UserCsv::Importer, type: :model, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:group1) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
  let!(:other_site) { create(:gws_group, name: unique_id) }
  let!(:other_site_group1) { create(:gws_group, name: "#{other_site.name}/#{unique_id}") }

  context 'with no forms' do
    let(:password) { unique_id }
    let(:webmail_support) { true }
    let(:file) do
      csv_file = "#{tmpdir}/#{unique_id}.csv"
      File.open(csv_file, "wb") do |f|
        exporter = Gws::UserCsv::Exporter.new(
          site: site, criteria: [ source_user ], encoding: "UTF-8", webmail_support: webmail_support)
        exporter.enum_csv.each do |row|
          terms = row.split(",")
          # set password
          terms[6] = password if terms[6].blank?
          row = terms.join(",")
          f.write row
        end
      end
      if respond_to?(:after_export)
        after_export.call
      end
      csv_file
    end

    before do
      if respond_to?(:before_import)
        before_import.call
      end
      Fs::UploadedFile.create_from_file(file) do |f|
        importer = Gws::UserCsv::Importer.new(
          cur_site: site, cur_user: user, webmail_support: webmail_support, in_file: f)
        importer.import
        expect(importer.imported).to eq 1
      end
    end

    context 'with required' do
      context 'with new user' do
        let(:source_user) do
          Gws::User.new(
            id: nil, name: unique_id, uid: unique_id, email: unique_email, in_password: unique_id,
            group_ids: [ group1.id, other_site_group1.id ]
          )
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.name).to eq source_user.name
            expect(user.uid).to eq source_user.uid
            expect(user.email).to eq source_user.email
            expect(user.password).to eq SS::Crypto.crypt(password)
            expect(user.group_ids).to eq [ group1.id ]
          end
        end
      end

      context 'with existing multi tenant user' do
        let!(:user1) { create :gws_user, group_ids: [ group1.id, other_site_group1.id ] }
        let!(:group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
        let(:source_user) do
          user = Gws::User.find(user1.id)
          user.name = unique_id
          user.uid = unique_id
          user.email = unique_email
          user.group_ids = [ group2.id ]
          user
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.name).to eq source_user.name
            expect(user.uid).to eq source_user.uid
            expect(user.email).to eq source_user.email
            expect(user.password).to eq SS::Crypto.crypt(password)
            expect(user.group_ids).to have(2).items
            expect(user.group_ids).to include(group2.id, other_site_group1.id)
          end
        end
      end
    end

    context 'with basic attributes 1' do
      let!(:title1) { create :gws_user_title, cur_site: site }
      let!(:title2) { create :gws_user_title, cur_site: site }
      let!(:other_site_title1) { create :gws_user_title, cur_site: other_site }
      let!(:occupation1) { create :gws_user_occupation, cur_site: site }
      let!(:occupation2) { create :gws_user_occupation, cur_site: site }
      let!(:other_site_occupation1) { create :gws_user_occupation, cur_site: other_site }

      context 'with new user' do
        let(:source_user) do
          build(
            :gws_user, id: nil, kana: unique_id, organization_uid: unique_id, organization_id: site.id,
            tel: unique_tel, tel_ext: unique_id, title_ids: [ title1.id, other_site_title1.id ],
            occupation_ids: [ occupation1.id, other_site_occupation1.id ], type: Gws::User::TYPE_SNS,
            group_ids: [ group1.id, other_site_group1.id ])
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.kana).to eq source_user.kana
            expect(user.organization_uid).to eq source_user.organization_uid
            expect(user.organization_id).to eq source_user.organization_id
            expect(user.tel).to eq source_user.tel
            expect(user.tel_ext).to eq source_user.tel_ext
            expect(user.title_ids).to eq [ title1.id ]
            expect(user.occupation_ids).to eq [ occupation1.id ]
            expect(user.type).to eq source_user.type
          end
        end
      end

      context 'with existing multi tenant user' do
        let(:user1) do
          create(
            :gws_user, kana: unique_id, organization_uid: unique_id, organization_id: site.id,
            tel: unique_tel, tel_ext: unique_id, title_ids: [ title1.id, other_site_title1.id ],
            occupation_ids: [ occupation1.id, other_site_occupation1.id ], type: Gws::User::TYPE_SNS,
            group_ids: [ group1.id, other_site_group1.id ])
        end
        let!(:group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
        let(:source_user) do
          user = Gws::User.find(user1.id)
          user.kana = unique_id
          user.organization_uid = unique_id
          user.tel = unique_tel
          user.tel_ext = unique_id
          user.title_ids = [ title2.id ]
          user.occupation_ids = [ occupation2.id ]
          user.type = Gws::User::TYPE_SNS
          user
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.kana).to eq source_user.kana
            expect(user.organization_uid).to eq source_user.organization_uid
            expect(user.organization_id).to eq source_user.organization_id
            expect(user.tel).to eq source_user.tel
            expect(user.tel_ext).to eq source_user.tel_ext
            expect(user.title_ids).to have(2).items
            expect(user.title_ids).to include(title2.id, other_site_title1.id)
            expect(user.occupation_ids).to have(2).items
            expect(user.occupation_ids).to include(occupation2.id, other_site_occupation1.id)
            expect(user.type).to eq source_user.type
          end
        end
      end
    end

    context 'with basic attributes 2' do
      let(:now) { Time.zone.now.beginning_of_minute }
      let!(:account_start_date) { now - 3.days }
      let!(:account_expiration_date) { now + 3.days }
      let!(:initial_password_warning) { [ nil, 1 ].sample }
      let!(:session_lifetime) { [ 300, 900, 1800, 3600 ].sample }
      let!(:restriction) { %w(none api_only).sample }
      let!(:lock_state) { %w(unlocked locked).sample }
      let!(:deletion_lock_state) { %w(unlocked locked).sample }

      context 'with new user' do
        let(:source_user) do
          build(
            :gws_user, id: nil, account_start_date: account_start_date, account_expiration_date: account_expiration_date,
            initial_password_warning: initial_password_warning, session_lifetime: session_lifetime, restriction: restriction,
            lock_state: lock_state, deletion_lock_state: deletion_lock_state)
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.account_start_date).to eq account_start_date
            expect(user.account_expiration_date).to eq account_expiration_date
            expect(user.initial_password_warning).to eq initial_password_warning
            expect(user.session_lifetime).to eq session_lifetime
            expect(user.restriction).to eq restriction
            expect(user.lock_state).to eq lock_state
            expect(user.deletion_lock_state).to eq deletion_lock_state
          end
        end
      end
    end

    context 'with basic attributes 3' do
      let!(:group2) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
      let!(:other_site_group2) { create(:gws_group, name: "#{other_site.name}/#{unique_id}") }
      let!(:switch_user1) { create :gws_user, group_ids: [ group1.id, other_site_group1.id ] }
      let!(:remark) { Array.new(2) { "remark-#{unique_id}" } }

      context 'with new user' do
        let(:source_user) do
          build(
            :gws_user, id: nil,
            gws_main_group_ids: { site.id.to_s => group1.id, other_site.id.to_s => other_site_group1.id },
            gws_default_group_ids: { site.id.to_s => group2.id, other_site.id.to_s => other_site_group2.id },
            switch_user: switch_user1, remark: remark.join("\r\n"),
            group_ids: [ site.id, group1.id, group2.id, other_site.id, other_site_group1.id, other_site_group2.id ])
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.gws_main_group_ids).to eq({ site.id.to_s => group1.id })
            expect(user.gws_default_group_ids).to eq({ site.id.to_s => group2.id })
            expect(user.switch_user_id).to eq switch_user1.id
            expect(user.remark).to eq remark.join("\r\n")
          end
        end
      end

      context 'with existing multi tenant user' do
        let(:user1) do
          create(
            :gws_user,
            gws_main_group_ids: { site.id.to_s => group1.id, other_site.id.to_s => other_site_group1.id },
            gws_default_group_ids: { site.id.to_s => group2.id, other_site.id.to_s => other_site_group2.id },
            switch_user: switch_user1, remark: remark.join("\r\n"),
            group_ids: [ site.id, group1.id, group2.id, other_site.id, other_site_group1.id, other_site_group2.id ])
        end
        let!(:group3) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
        let!(:group4) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
        let!(:other_site_user1) { create :gws_user, group_ids: [ other_site_group1.id ] }
        let(:source_user) do
          user = Gws::User.find(user1.id)
          user.gws_main_group_ids = { site.id.to_s => group3.id }
          user.gws_default_group_ids = { site.id.to_s => group4.id }
          user.switch_user = other_site_user1
          user.group_ids = user.group_ids + [ group3.id, group4.id ]
          user
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.gws_main_group_ids).to include(site.id.to_s => group3.id)
            expect(user.gws_main_group_ids).to include(other_site.id.to_s => other_site_group1.id)
            expect(user.gws_default_group_ids).to include(site.id.to_s => group4.id)
            expect(user.gws_default_group_ids).to include(other_site.id.to_s => other_site_group2.id)
            expect(user.switch_user).to be_blank
          end
        end
      end
    end

    context 'with locale setting' do
      let!(:lang) { I18n.available_locales.sample.to_s }
      let!(:timezone) { ActiveSupport::TimeZone.all.sample }

      context 'with new user' do
        let(:source_user) do
          build(:gws_user, id: nil, lang: lang, timezone: timezone.name)
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.lang).to eq lang
            expect(user.timezone).to eq timezone.name
          end
        end
      end
    end

    context 'with ldap' do
      let!(:ldap_dn) { "dc=dc-#{unique_id},dc=city,dc=example,dc=jp" }

      context 'with new user' do
        let(:source_user) do
          build(:gws_user, id: nil, type: Gws::User::TYPE_LDAP, ldap_dn: ldap_dn)
        end
        let(:password) { nil }

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.type).to eq Gws::User::TYPE_LDAP
            expect(user.ldap_dn).to eq ldap_dn
            expect(user.password).to be_blank
          end
        end
      end
    end

    context 'with public duty' do
      let!(:charge_name) { "charge_name-#{unique_id}" }
      let!(:charge_address) { "charge_address-#{unique_id}" }
      let!(:charge_tel) { unique_tel }
      let!(:divide_duties) { Array.new(2) { "divide_duties-#{unique_id}" } }

      context 'with new user' do
        let(:source_user) do
          build(
            :gws_user, id: nil, charge_name: charge_name, charge_address: charge_address, charge_tel: charge_tel,
            divide_duties: divide_duties.join("\r\n"))
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.charge_name).to eq charge_name
            expect(user.charge_address).to eq charge_address
            expect(user.charge_tel).to eq charge_tel
            expect(user.divide_duties).to eq divide_duties.join("\r\n")
          end
        end
      end
    end

    context 'with affair' do
      let!(:staff_category) { I18n.t("gws/affair.options.staff_category").keys.sample.to_s }
      let!(:staff_address_uid) { "staff_address_uid-#{unique_id}" }
      let!(:superior_user1) { create :gws_user, group_ids: [ group1.id ] }
      let!(:other_site_superior_user1) { create :gws_user, group_ids: [ other_site_group1.id ] }

      context 'with new user' do
        let(:source_user) do
          build(
            :gws_user, id: nil, staff_category: staff_category, staff_address_uid: staff_address_uid,
            gws_superior_group_ids: { site.id.to_s => [ group1.id ], other_site.id.to_s => [ other_site_group1.id ] },
            gws_superior_user_ids: {
              site.id.to_s => [ superior_user1.id ],
              other_site.id.to_s => [ other_site_superior_user1.id ]
            },
            group_ids: [ site.id, group1.id, other_site.id, other_site_group1.id ])
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.staff_category).to eq staff_category
            expect(user.staff_address_uid).to eq staff_address_uid
            expect(user.gws_superior_group_ids).to eq({ site.id.to_s => [ group1.id ] })
            expect(user.gws_superior_user_ids).to eq({ site.id.to_s => [ superior_user1.id ] })
          end
        end
      end

      context 'with existing multi tenant user' do
        let(:user1) do
          create(
            :gws_user, staff_category: staff_category, staff_address_uid: staff_address_uid,
            gws_superior_group_ids: { site.id.to_s => [ group1.id ], other_site.id.to_s => [ other_site_group1.id ] },
            gws_superior_user_ids: {
              site.id.to_s => [ superior_user1.id ],
              other_site.id.to_s => [ other_site_superior_user1.id ]
            },
            group_ids: [ site.id, group1.id, other_site.id, other_site_group1.id ])
        end
        let!(:group3) { create(:gws_group, name: "#{site.name}/#{unique_id}") }
        let!(:superior_user2) { create :gws_user, group_ids: [ group1.id ] }
        let(:source_user) do
          user = Gws::User.find(user1.id)
          user.gws_superior_group_ids = { site.id.to_s => [ group3.id ] }
          user.gws_superior_user_ids = { site.id.to_s => [ superior_user2.id ] }
          user.group_ids = user.group_ids + [ group3.id ]
          user
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.staff_category).to eq staff_category
            expect(user.staff_address_uid).to eq staff_address_uid
            expect(user.gws_superior_group_ids).to include({ site.id.to_s => [ group3.id ] })
            expect(user.gws_superior_group_ids).to include({ other_site.id.to_s => [ other_site_group1.id ] })
            expect(user.gws_superior_user_ids).to include({ site.id.to_s => [ superior_user2.id ] })
            expect(user.gws_superior_user_ids).to include({ other_site.id.to_s => [ other_site_superior_user1.id ] })
          end
        end
      end
    end

    context 'with gws role' do
      let!(:role1) { create :gws_role, cur_site: site }
      let!(:other_site_role1) { create :gws_role, cur_site: other_site }

      context 'with new user' do
        let(:source_user) do
          build(
            :gws_user, id: nil, gws_role_ids: [ role1.id, other_site_role1.id ],
            group_ids: [ site.id, group1.id, other_site.id, other_site_group1.id ]
          )
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.gws_role_ids).to eq [ role1.id ]
          end
        end
      end

      context 'with existing multi tenant user' do
        let!(:role1) { create :gws_role, cur_site: site }
        let!(:role2) { create :gws_role, cur_site: site }
        let!(:other_site_role1) { create :gws_role, cur_site: other_site }
        let(:user1) do
          create(
            :gws_user, gws_role_ids: [ role1.id, other_site_role1.id ],
            group_ids: [ site.id, group1.id, other_site.id, other_site_group1.id ])
        end
        let(:source_user) do
          user = Gws::User.find(user1.id)
          user.gws_role_ids = [ role2.id ]
          user
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.gws_role_ids).to have(2).items
            expect(user.gws_role_ids).to include(role2.id, other_site_role1.id)
          end
        end
      end
    end

    context 'with sys role' do
      let!(:general_at_export_privileged_at_import_role) { create :sys_role, name: unique_id, permissions: %w(use_gws) }
      let!(:general_role1) { create :sys_role, name: unique_id, permissions: %w(use_gws) }
      let!(:before_import) do
        proc do
          general_at_export_privileged_at_import_role.update!(permissions: %w(use_gws edit_sys_groups))
        end
      end

      context 'with new user' do
        let(:source_user) do
          build(
            :gws_user, id: nil, sys_role_ids: [ general_at_export_privileged_at_import_role.id, general_role1.id ],
            group_ids: [ site.id ]
          )
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            # 特権権限はインポート不可
            expect(user.sys_role_ids).to eq [ general_role1.id ]
          end
        end
      end

      context 'with existing multi tenant user' do
        let(:user1) do
          create(
            :gws_user, sys_role_ids: [ general_at_export_privileged_at_import_role.id, general_role1.id ],
            group_ids: [ site.id ])
        end
        let!(:general_role2) { create :sys_role, name: unique_id, permissions: %w(use_gws) }
        let(:source_user) do
          user = Gws::User.find(user1.id)
          user.sys_role_ids = [ general_role2.id ]
          user
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.sys_role_ids).to have(2).items
            # インポート時、特権権限は削除されず、一般権限のみ削除される
            expect(user.sys_role_ids).to include(general_role2.id, general_at_export_privileged_at_import_role.id)
          end
        end
      end
    end

    context 'with webmail role' do
      let!(:role1) { create :webmail_role }

      context 'with new user' do
        let(:source_user) { build(:gws_user, id: nil, webmail_role_ids: [ role1.id ]) }

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |user|
            expect(user).to be_persisted
            expect(user.webmail_role_ids).to eq [ role1.id ]
          end
        end
      end
    end

    context 'with readable' do
      let!(:role1) { create :webmail_role }
      let!(:readable_user1) { create :gws_user, group_ids: [ group1.id ] }

      context 'with new user' do
        let(:readable_setting_range) { %w(public select private).sample }
        let(:source_user) do
          build(
            :gws_user, id: nil, readable_setting_range: readable_setting_range,
            readable_group_ids: [ group1.id], readable_member_ids: [ readable_user1.id ],
          )
        end

        it do
          Gws::User.unscoped.find_by(uid: source_user.uid).tap do |imported_user|
            expect(imported_user).to be_persisted
            expect(imported_user.readable_setting_range).to eq source_user.readable_setting_range
            case imported_user.readable_setting_range
            when 'select'
              expect(imported_user.readable_group_ids).to eq source_user.readable_group_ids
              expect(imported_user.readable_member_ids).to eq source_user.readable_member_ids
            when 'private'
              expect(imported_user.readable_group_ids).to be_blank
              expect(imported_user.readable_member_ids).to eq [ user.id ]
            else
              expect(imported_user.readable_group_ids).to be_blank
              expect(imported_user.readable_member_ids).to be_blank
            end
          end
        end
      end
    end
  end

  context 'with form' do
    let!(:title) { create(:gws_user_title, code: 'E100', name: '社長') }
    let!(:occupation) { create(:gws_user_occupation, code: 'B133', name: '看護師') }
    let!(:sys_role1) { create(:sys_role_general, name: "一般ユーザー") }
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
