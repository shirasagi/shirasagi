require 'spec_helper'

describe Gws::Ldap::SyncJob, dbscope: :example, ldap: true do
  let!(:site) { create :gws_group }
  let!(:task) { Gws::Ldap::SyncTask.site(site).first_or_create }
  let!(:role) { create :gws_role, cur_site: site }
  let(:now) { Time.zone.now.beginning_of_minute }

  before do
    SS::LdapSupport.ldap_add Rails.root.join("spec/fixtures/ldap/shirasagi2.ldif")

    site.ldap_use_state = "individual"
    site.ldap_url = "ldap://localhost:#{SS::LdapSupport.docker_ldap_port}/"
    site.save!

    task.admin_dn = "cn=admin,dc=example,dc=jp"
    task.admin_password = SS::Crypto.encrypt("admin")

    task.group_base_dn = "dc=example,dc=jp"
    task.group_scope = "whole_subtree"
    task.group_filter = "(objectClass=ssGroup)"
    task.group_root_dn = "cn=シラサギ市, ou=Users, dc=shirasagi-city, dc=example, dc=jp"

    task.user_base_dn = "dc=example,dc=jp"
    task.user_scope = "whole_subtree"
    task.user_filter = "(objectClass=ssUser)"
    task.user_role_ids = [ role.id ]

    task.state = "ready"
    task.save!
  end

  after do
    SS::LdapSupport.stop_ldap_service
  end

  context "simply import groups / users with 'shirasagi2.ldif'" do
    it do
      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      group_map = {}
      expect(Gws::Group.all.site(site).exists(ldap_dn: true).count).to eq 7
      # 0
      ::Ldap.normalize_dn("cn=シラサギ市, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.id).to eq site.id
          expect(group.name).to eq site.name

          group_map[::File.basename(group.name)] = group
        end
      end
      # 1
      ::Ldap.normalize_dn("cn=企画政策部, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site.name}/企画政策部"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 2
      ::Ldap.normalize_dn("cn=危機管理部, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site.name}/危機管理部"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 3
      ::Ldap.normalize_dn("cn=政策課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site.name}/企画政策部/政策課"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 4
      ::Ldap.normalize_dn("cn=広報課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site.name}/企画政策部/広報課"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 5
      ::Ldap.normalize_dn("cn=管理課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site.name}/危機管理部/管理課"
          group_map[::File.basename(group.name)] = group
        end
      end
      # 6
      ::Ldap.normalize_dn("cn=防災課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.name).to eq "#{site.name}/危機管理部/防災課"
          group_map[::File.basename(group.name)] = group
        end
      end

      expect(Gws::User.all.site(site).exists(ldap_dn: true).count).to eq 7
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
          expect(user.occupation_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role.id ]
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
          expect(user.occupation_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role.id ]
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
          expect(user.occupation_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site.id
          expect(user.group_ids).to eq [ group_map["政策課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role.id ]
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
          expect(user.occupation_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site.id
          expect(user.group_ids).to eq [ group_map["管理課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role.id ]
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
          expect(user.occupation_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site.id
          expect(user.group_ids).to eq [ group_map["広報課"].id, group_map["防災課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role.id ]
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
          expect(user.occupation_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to be_blank
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site.id
          expect(user.group_ids).to eq [ group_map["管理課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role.id ]
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
          expect(user.occupation_ids).to be_blank
          expect(user.type).to eq Gws::User::TYPE_LDAP
          expect(user.account_start_date).to be_blank
          expect(user.account_expiration_date).to eq Time.zone.parse("2029-09-30 09:00")
          expect(user.initial_password_warning).to be_blank
          expect(user.session_lifetime).to be_blank
          expect(user.restriction).to be_blank
          expect(user.lock_state).to be_blank
          expect(user.deletion_lock_state).to eq "unlocked"
          expect(user.organization_id).to eq site.id
          expect(user.group_ids).to eq [ group_map["広報課"].id ]
          expect(user.gws_main_group_ids).to be_blank
          expect(user.gws_default_group_ids).to be_blank
          expect(user.switch_user_id).to be_blank
          expect(user.remark).to be_blank
          # LDAP
          expect(user.ldap_dn).to eq dn
          # 権限/ロール
          expect(user.gws_role_ids).to eq [ role.id ]
          # 閲覧権限
          expect(user.readable_setting_range).to eq "select"
          expect(user.readable_member_ids).to be_blank
          expect(user.readable_group_ids).to be_blank
          expect(user.readable_custom_group_ids).to be_blank
        end
      end
    end
  end

  context "user's name is changed" do
    before do
      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Group.all.site(site).exists(ldap_dn: true).count).to eq 7
      expect(Gws::User.all.site(site).exists(ldap_dn: true).count).to eq 7
    end

    it do
      ::Ldap.normalize_dn("cn=ldap_user2, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.name).to eq "渡辺 和子"
        end
      end

      SS::LdapSupport.ldap_modify <<~LDIF
        dn: cn=ldap_user2, ou=Users, dc=shirasagi-city, dc=example, dc=jp
        changetype: modify
        replace: displayName
        displayName: 佐藤 和子
        -
        replace: sn
        sn: 佐藤
      LDIF

      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Ldap.normalize_dn("cn=ldap_user2, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.name).to eq "佐藤 和子"
        end
      end
    end
  end

  context "user's uid and email is changed" do
    before do
      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Group.all.site(site).exists(ldap_dn: true).count).to eq 7
      expect(Gws::User.all.site(site).exists(ldap_dn: true).count).to eq 7
    end

    it do
      ::Ldap.normalize_dn("cn=ldap_user3, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.uid).to eq "ldap_user3"
          expect(user.email).to eq "ldap_user3@example.jp"
        end
      end

      SS::LdapSupport.ldap_modify <<~LDIF
        dn: cn=ldap_user3, ou=Users, dc=shirasagi-city, dc=example, dc=jp
        changetype: modify
        replace: userPrincipalName
        userPrincipalName: ldap_user99@example.jp
        -
        replace: sAMAccountName
        sAMAccountName: ldap_user99
      LDIF

      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Ldap.normalize_dn("cn=ldap_user3, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.uid).to eq "ldap_user99"
          expect(user.email).to eq "ldap_user99@example.jp"
        end
      end
    end
  end

  context "user's groups is changed" do
    before do
      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Group.all.site(site).exists(ldap_dn: true).count).to eq 7
      expect(Gws::User.all.site(site).exists(ldap_dn: true).count).to eq 7
    end

    it do
      ::Ldap.normalize_dn("cn=ldap_user5, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.groups.pluck(:name)).to eq [ "#{site.name}/企画政策部/広報課" ]
        end
      end

      SS::LdapSupport.ldap_modify <<~LDIF
        dn: cn=広報課, ou=Users, dc=shirasagi-city, dc=example, dc=jp
        changetype: modify
        replace: member
        member: cn=ldap_user3, ou=Users, dc=shirasagi-city, dc=example, dc=jp

        dn: cn=管理課, ou=Users, dc=shirasagi-city, dc=example, dc=jp
        changetype: modify
        add: member
        member: cn=ldap_user5, ou=Users, dc=shirasagi-city, dc=example, dc=jp
      LDIF

      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Ldap.normalize_dn("cn=ldap_user5, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.groups.pluck(:name)).to eq [ "#{site.name}/危機管理部/管理課" ]
        end
      end
    end
  end

  context "flag 'isDeleted' is set" do
    before do
      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Group.all.site(site).exists(ldap_dn: true).count).to eq 7
      expect(Gws::User.all.site(site).exists(ldap_dn: true).count).to eq 7
    end

    it do
      ::Ldap.normalize_dn("cn=ldap_user4, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.account_expiration_date).to be_blank
        end
      end

      SS::LdapSupport.ldap_modify <<~LDIF
        dn: cn=ldap_user4, ou=Users, dc=shirasagi-city, dc=example, dc=jp
        changetype: modify
        add: isDeleted
        isDeleted: TRUE
      LDIF

      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Ldap.normalize_dn("cn=ldap_user4, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.account_expiration_date).to eq Time.zone.now.change(hour: 0)
        end
      end
    end
  end

  context "user's ldap entry is deleted" do
    before do
      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Group.all.site(site).exists(ldap_dn: true).count).to eq 7
      expect(Gws::User.all.site(site).exists(ldap_dn: true).count).to eq 7
    end

    it do
      ::Ldap.normalize_dn("cn=ldap_user4, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.account_expiration_date).to be_blank
        end
      end

      SS::LdapSupport.ldap_modify <<~LDIF
        dn: cn=ldap_user4, ou=Users, dc=shirasagi-city, dc=example, dc=jp
        changetype: delete
      LDIF

      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Ldap.normalize_dn("cn=ldap_user4, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::User.all.where(ldap_dn: dn).first.tap do |user|
          expect(user.account_expiration_date).to eq Time.zone.now.change(hour: 0)
        end
      end
    end
  end

  context "group's ldap entry is deleted" do
    before do
      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Gws::Group.all.site(site).exists(ldap_dn: true).count).to eq 7
      expect(Gws::User.all.site(site).exists(ldap_dn: true).count).to eq 7
    end

    it do
      ::Ldap.normalize_dn("cn=防災課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.expiration_date).to be_blank
        end
      end

      SS::LdapSupport.ldap_modify <<~LDIF
        dn: cn=防災課, ou=Users, dc=shirasagi-city, dc=example, dc=jp
        changetype: delete
      LDIF

      expect { ss_perform_now described_class.bind(site_id: site, task_id: task) }.to output.to_stdout

      expect(Job::Log.all.count).to eq 2
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      ::Ldap.normalize_dn("cn=防災課, ou=Users, dc=shirasagi-city, dc=example, dc=jp").tap do |dn|
        Gws::Group.all.where(ldap_dn: dn).first.tap do |group|
          expect(group.expiration_date).to eq Time.zone.now.change(hour: 0)
        end
      end
    end
  end
end
