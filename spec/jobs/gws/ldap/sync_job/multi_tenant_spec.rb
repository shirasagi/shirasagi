require 'spec_helper'

describe Gws::Ldap::SyncJob, dbscope: :example, ldap: true do
  let!(:site1) { create :gws_group }
  let!(:site2) { create :gws_group }
  let!(:role1) { create :gws_role, cur_site: site1 }
  let!(:role2) { create :gws_role, cur_site: site2 }
  let!(:task1) { Gws::Ldap::SyncTask.site(site1).first_or_create }
  let!(:task2) { Gws::Ldap::SyncTask.site(site2).first_or_create }
  let(:now) { Time.zone.now.beginning_of_minute }

  before do
    SS::LdapSupport.ldap_add Rails.root.join("spec/fixtures/ldap/shirasagi2.ldif")

    [ site1, site2 ].each do |site|
      site.ldap_use_state = "individual"
      site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
      site.save!
    end

    [ task1, task2 ].each do |task|
      task.admin_dn = "cn=admin,dc=example,dc=jp"
      task.admin_password = SS::Crypto.encrypt("admin")

      task.group_base_dn = "dc=example,dc=jp"
      task.group_scope = "whole_subtree"
      task.group_filter = "(objectClass=ssGroup)"
      # task.group_root_dn = "cn=シラサギ市, ou=Users, dc=shirasagi-city, dc=example, dc=jp"

      task.user_base_dn = "dc=example,dc=jp"
      task.user_scope = "whole_subtree"
      # task.user_filter = "(objectClass=ssUser)"
      # task.user_role_ids = [ role.id ]

      task.state = "ready"
      task.save!
    end

    # シラサギ市/企画政策部
    task1.group_root_dn = "cn=企画政策部, ou=Users, dc=shirasagi-city, dc=example, dc=jp"
    task1.user_filter = "(&(objectClass=ssUser)(|(cn=ldap_sys)(cn=ldap_admin)(cn=ldap_user1)(cn=ldap_user3)(cn=ldap_user5)))"
    task1.user_role_ids = [ role1.id ]
    task1.save!

    # シラサギ市/危機管理部
    task2.group_root_dn = "cn=危機管理部, ou=Users, dc=shirasagi-city, dc=example, dc=jp"
    task2.user_filter = "(&(objectClass=ssUser)(|(cn=ldap_user2)(cn=ldap_user3)(cn=ldap_user4)))"
    task2.user_role_ids = [ role2.id ]
    task2.save!
  end

  after do
    SS::LdapSupport.stop_ldap_service
  end

  context "simply import groups / users on site1" do
    it do
      expect { described_class.bind(site_id: site1, task_id: task1).perform_now }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      group_map = {}
      expect(Gws::Group.all.site(site1).exists(ldap_dn: true).count).to eq 3
      # 0
      ::Ldap.normalize_dn("cn=企画政策部, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.id).to eq site1.id
          expect(group.name).to eq site1.name

          group_map[::File.basename(group.name)] = group
        end
      end
      # 1
      ::Ldap.normalize_dn("cn=政策課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site1.name}/政策課"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 2
      ::Ldap.normalize_dn("cn=広報課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site1.name}/広報課"
          group_map[::File.basename(group.name)] = group
        end
      end

      expect(Gws::User.all.site(site1).exists(ldap_dn: true).count).to eq 5
      # 0
      ::Ldap.normalize_dn("cn=ldap_sys, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "システム管理者"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_sys"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_sys@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 1
      ::Ldap.normalize_dn("cn=ldap_admin, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "サイト管理者"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_admin"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_admin@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 2
      ::Ldap.normalize_dn("cn=ldap_user1, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "鈴木 茂"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user1"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user1@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 3
      ::Ldap.normalize_dn("cn=ldap_user3, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "斎藤　拓也"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user3"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user3@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["広報課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 4
      ::Ldap.normalize_dn("cn=ldap_user5, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "高橋 清"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user5"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user5@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to eq Time.zone.parse("2029-09-30 09:00")
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["広報課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
    end
  end

  context "simply import groups / users on site2" do
    it do
      expect { described_class.bind(site_id: site2, task_id: task2).perform_now }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      group_map = {}
      expect(Gws::Group.all.site(site2).exists(ldap_dn: true).count).to eq 3
      # 0
      ::Ldap.normalize_dn("cn=危機管理部, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.id).to eq site2.id
          expect(group.name).to eq site2.name

          group_map[::File.basename(group.name)] = group
        end
      end
      # 1
      ::Ldap.normalize_dn("cn=管理課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site2.name}/管理課"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 2
      ::Ldap.normalize_dn("cn=防災課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site2.name}/防災課"
          group_map[::File.basename(group.name)] = group
        end
      end

      expect(Gws::User.all.site(site2).exists(ldap_dn: true).count).to eq 3
      # 0
      ::Ldap.normalize_dn("cn=ldap_user2, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "渡辺 和子"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user2"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user2@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site2.id
          expect(user.group_ids).to eq [ group_map["管理課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role2.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 1
      ::Ldap.normalize_dn("cn=ldap_user3, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "斎藤　拓也"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user3"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user3@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site2.id
          expect(user.group_ids).to eq [ group_map["防災課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role2.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 2
      ::Ldap.normalize_dn("cn=ldap_user4, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "伊藤 幸子"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user4"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user4@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site2.id
          expect(user.group_ids).to eq [ group_map["管理課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role2.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
    end
  end

  context "import groups / users on site1 and then import groups / users on site2" do
    it do
      expect { described_class.bind(site_id: site1, task_id: task1).perform_now }.to output.to_stdout
      expect { described_class.bind(site_id: site2, task_id: task2).perform_now }.to output.to_stdout

      expect(Job::Log.all.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      group_map = {}
      expect(Gws::Group.all.site(site1).exists(ldap_dn: true).count).to eq 3
      expect(Gws::Group.all.site(site2).exists(ldap_dn: true).count).to eq 3
      expect(Gws::Group.all.exists(ldap_dn: true).count).to eq 6
      # 0
      ::Ldap.normalize_dn("cn=企画政策部, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.id).to eq site1.id
          expect(group.name).to eq site1.name

          group_map[::File.basename(group.name)] = group
        end
      end
      # 1
      ::Ldap.normalize_dn("cn=政策課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site1.name}/政策課"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 2
      ::Ldap.normalize_dn("cn=広報課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site1.name}/広報課"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 3
      ::Ldap.normalize_dn("cn=危機管理部, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.id).to eq site2.id
          expect(group.name).to eq site2.name

          group_map[::File.basename(group.name)] = group
        end
      end
      # 4
      ::Ldap.normalize_dn("cn=管理課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site2.name}/管理課"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 5
      ::Ldap.normalize_dn("cn=防災課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site2.name}/防災課"
          group_map[::File.basename(group.name)] = group
        end
      end

      # puts "selector1=#{Gws::User.all.site(site1).selector}"
      # puts "selector2=#{Gws::User.all.site(site2).selector}"
      # expect(Gws::User.all.site(site1).exists(ldap_dn: true).count).to eq 5
      # expect(Gws::User.all.site(site2).exists(ldap_dn: true).count).to eq 3
      expect(Gws::User.all.exists(ldap_dn: true).count).to eq 7
      # 0
      ::Ldap.normalize_dn("cn=ldap_sys, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "システム管理者"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_sys"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_sys@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 1
      ::Ldap.normalize_dn("cn=ldap_admin, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "サイト管理者"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_admin"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_admin@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 2
      ::Ldap.normalize_dn("cn=ldap_user1, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "鈴木 茂"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user1"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user1@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 3
      ::Ldap.normalize_dn("cn=ldap_user2, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "渡辺 和子"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user2"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user2@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site2.id
          expect(user.group_ids).to eq [ group_map["管理課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role2.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 4
      ::Ldap.normalize_dn("cn=ldap_user3, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "斎藤　拓也"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user3"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user3@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["広報課"].id, group_map["防災課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id, role2.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 5
      ::Ldap.normalize_dn("cn=ldap_user4, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "伊藤 幸子"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user4"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user4@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site2.id
          expect(user.group_ids).to eq [ group_map["管理課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role2.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
      # 6
      ::Ldap.normalize_dn("cn=ldap_user5, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          # 基本情報
          expect(user.name).to eq "高橋 清"
          expect(user.kana).to be_blank
          expect(user.uid).to eq "ldap_user5"
          expect(user.organization_uid).to be_blank
          expect(user.email).to eq "ldap_user5@example.jp"
          expect(user.password).to be_blank
          expect(user.tel).to be_blank
          expect(user.tel_ext).to be_blank
          expect(user.title_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to eq Time.zone.parse("2029-09-30 09:00")
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site1.id
          expect(user.group_ids).to eq [ group_map["広報課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role1.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
    end
  end
end
