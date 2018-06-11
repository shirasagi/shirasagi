require 'spec_helper'

describe Gws::Notice::Folder, type: :model, dbscope: :example do
  describe '.create_my_folder!' do
    let(:default_notice_individual_body_size_limit) { 240 }
    let(:default_notice_total_body_size_limit) { SS.config.gws.notice['default_notice_total_body_size_limit'] }
    let(:default_notice_individual_file_size_limit) { SS.config.gws.notice['default_notice_individual_file_size_limit'] }
    let(:default_notice_total_file_size_limit) { SS.config.gws.notice['default_notice_total_file_size_limit'] }
    let!(:group0) { create(:gws_group) }
    let!(:group1) { create(:gws_group, name: "#{group0.name}/#{unique_id}") }
    let!(:group2) { create(:gws_group, name: "#{group0.name}/#{unique_id}") }

    context 'when there are no folders' do
      subject { described_class.create_my_folder!(group0, group1) }

      it do
        expect(subject.name).to eq group1.name
        expect(subject.notice_individual_body_size_limit).to eq default_notice_individual_body_size_limit
        expect(subject.notice_total_body_size_limit).to eq default_notice_total_body_size_limit
        expect(subject.notice_individual_file_size_limit).to eq default_notice_individual_file_size_limit
        expect(subject.notice_total_file_size_limit).to eq default_notice_total_file_size_limit
        expect(subject.member_group_ids).to eq [group1.id]
        expect(subject.readable_setting_range).to eq 'select'
        expect(subject.readable_group_ids).to eq [group1.id]
        expect(subject.group_ids).to eq [group1.id]

        expect { described_class.find_by(name: group2.name) }.to raise_error Mongoid::Errors::DocumentNotFound

        described_class.find_by(name: group0.name).tap do |parent_folder|
          expect(parent_folder.name).to eq group0.name
          expect(parent_folder.notice_individual_body_size_limit).to eq default_notice_individual_body_size_limit
          expect(parent_folder.notice_total_body_size_limit).to eq default_notice_total_body_size_limit
          expect(parent_folder.notice_individual_file_size_limit).to eq default_notice_individual_file_size_limit
          expect(parent_folder.notice_total_file_size_limit).to eq default_notice_total_file_size_limit
          expect(parent_folder.member_group_ids).to eq [group0.id]
          expect(parent_folder.readable_setting_range).to eq 'select'
          expect(parent_folder.readable_group_ids).to include(group0.id, group1.id, group2.id)
          expect(parent_folder.group_ids).to eq [group0.id]
        end
      end
    end

    context 'when parent folder is existed' do
      let(:parent_folder) { described_class.create_my_folder!(group0, group0) }
      subject { described_class.create_my_folder!(group0, group1) }

      before do
        parent_folder.notice_individual_body_size_limit = rand(100..200)
        parent_folder.notice_total_body_size_limit_mb = rand(100..200)
        parent_folder.notice_individual_file_size_limit_mb = rand(100..200)
        parent_folder.notice_total_file_size_limit_mb = rand(100..200)
        parent_folder.save!
      end

      it do
        # In this case, a folder inherits some attributes from parent folder
        expect(subject.name).to eq group1.name
        expect(subject.notice_individual_body_size_limit).to eq parent_folder.notice_individual_body_size_limit
        expect(subject.notice_total_body_size_limit).to eq parent_folder.notice_total_body_size_limit
        expect(subject.notice_individual_file_size_limit).to eq parent_folder.notice_individual_file_size_limit
        expect(subject.notice_total_file_size_limit).to eq parent_folder.notice_total_file_size_limit
        expect(subject.member_group_ids).to eq [group1.id]
        expect(subject.readable_setting_range).to eq 'select'
        expect(subject.readable_group_ids).to eq [group1.id]
        expect(subject.group_ids).to eq [group1.id]

        expect { described_class.find_by(name: group2.name) }.to raise_error Mongoid::Errors::DocumentNotFound

        expect(parent_folder.name).to eq group0.name
        expect(parent_folder.member_group_ids).to eq [group0.id]
        expect(parent_folder.readable_setting_range).to eq 'select'
        expect(parent_folder.readable_group_ids).to include(group0.id, group1.id, group2.id)
        expect(parent_folder.group_ids).to eq [group0.id]
      end
    end
  end

  describe '.for_post_xxx' do
    let(:site) { gws_site }
    let(:folder) { create(:gws_notice_folder, cur_site: site, cur_user: gws_user) }
    let(:user) { create(:gws_user, group_ids: [ site.id ]) }

    context 'when readable user is given' do
      before do
        folder.readable_setting_range = 'select'
        folder.readable_member_ids = [ user.id ]
        folder.readable_group_ids = []
        folder.readable_custom_group_ids = []

        folder.member_ids = [ gws_user.id ]
        folder.member_group_ids = []
        folder.member_custom_group_ids = []

        folder.user_ids = [ gws_user.id ]
        folder.group_ids = []

        folder.save!
      end

      it do
        expect(described_class.for_post_reader(site, user).count).to eq 1
        expect(described_class.for_post_reader(site, user).first).to eq folder

        expect(described_class.for_post_editor(site, user).count).to eq 1
        expect(described_class.for_post_editor(site, user).first).to eq folder

        expect(described_class.for_post_manager(site, user).count).to eq 0
      end
    end

    context 'when editable user is given' do
      before do
        folder.readable_setting_range = 'select'
        folder.readable_member_ids = [ gws_user.id ]
        folder.readable_group_ids = []
        folder.readable_custom_group_ids = []

        folder.member_ids = [ user.id ]
        folder.member_group_ids = []
        folder.member_custom_group_ids = []

        folder.user_ids = [ gws_user.id ]
        folder.group_ids = []

        folder.save!
      end

      it do
        expect(described_class.for_post_reader(site, user).count).to eq 0

        expect(described_class.for_post_editor(site, user).count).to eq 1
        expect(described_class.for_post_editor(site, user).first).to eq folder

        expect(described_class.for_post_manager(site, user).count).to eq 0
      end
    end

    context 'when administrative user is given' do
      let(:role) { create(:gws_role_notice_admin) }

      before do
        user.gws_role_ids = [ role.id ]
        user.save!

        folder.readable_setting_range = 'select'
        folder.readable_member_ids = [ gws_user.id ]
        folder.readable_group_ids = []
        folder.readable_custom_group_ids = []

        folder.member_ids = [ gws_user.id ]
        folder.member_group_ids = []
        folder.member_custom_group_ids = []

        folder.user_ids = [ user.id ]
        folder.group_ids = []

        folder.save!
      end

      it do
        expect(described_class.for_post_reader(site, user).count).to eq 0

        expect(described_class.for_post_editor(site, user).count).to eq 0

        expect(described_class.for_post_manager(site, user).count).to eq 1
      end
    end
  end
end
