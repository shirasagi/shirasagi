require 'spec_helper'

describe Chorg::MainRunner, dbscope: :example do
  let(:root_group) { create(:revision_root_group) }
  let(:site) { create(:cms_site, group_ids: [root_group.id]) }
  let(:task) { Chorg::Task.create!(name: unique_id, site_id: site) }
  let(:job_opts) { { 'newly_created_group_to_site' => 'add' } }

  # ページの電話番号、ファックス番号、メールアドレスを一括置換する目的で、移動を用いる
  context 'when move is used to update tel, fax, email in all pages' do
    context "non-empty to non-empty" do
      let(:group_attributes) do
        {
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id,
          main_state: "main"
        }
      end
      let!(:group1) { create(:revision_new_group, contact_groups: [ group_attributes ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination) do
        {
          name: group1.name,
          order: "",
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id,
          ldap_dn: ""
        }
      end
      let!(:changeset) do
        create(
          :move_changeset, revision_id: revision.id, source: group1, destinations: [ destination.stringify_keys ]
        )
      end
      # group1 と同じ情報が連絡先にセットされているページ
      let!(:page1) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: group1.contact_email,
          contact_tel: group1.contact_tel,
          contact_fax: group1.contact_fax,
          contact_link_url: group1.contact_link_url,
          contact_link_name: group1.contact_link_name
        )
      end
      # 連絡先が空のページ
      let!(:page2) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: "",
          contact_tel: "",
          contact_fax: "",
          contact_link_url: "",
          contact_link_name: ""
        )
      end
      # 連絡先に異なる情報がセットされているページ
      let!(:page3) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id
        )
      end

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        group1.reload
        expect(group1.contact_email).to eq destination[:contact_email]
        expect(group1.contact_tel).to eq destination[:contact_tel]
        expect(group1.contact_fax).to eq destination[:contact_fax]
        expect(group1.contact_link_url).to eq destination[:contact_link_url]
        expect(group1.contact_link_name).to eq destination[:contact_link_name]

        # check page
        page1.reload
        expect(page1.group_ids).to eq [ group1.id ]
        expect(page1.contact_group_id).to eq group1.id
        expect(page1.contact_email).to eq group1.contact_email
        expect(page1.contact_tel).to eq group1.contact_tel
        expect(page1.contact_fax).to eq group1.contact_fax
        expect(page1.contact_link_url).to eq group1.contact_link_url
        expect(page1.contact_link_name).to eq group1.contact_link_name

        page2.reload
        expect(page2.group_ids).to eq [ group1.id ]
        expect(page2.contact_group_id).to eq group1.id
        expect(page2.contact_email).to be_blank
        expect(page2.contact_tel).to be_blank
        expect(page2.contact_fax).to be_blank
        expect(page2.contact_link_url).to be_blank
        expect(page2.contact_link_name).to be_blank

        page3.reload
        expect(page3.group_ids).to eq [ group1.id ]
        expect(page3.contact_group_id).to eq group1.id
        expect(page3.contact_email).not_to eq group1.contact_email
        expect(page3.contact_tel).not_to eq group1.contact_tel
        expect(page3.contact_fax).not_to eq group1.contact_fax
        expect(page3.contact_link_url).not_to eq group1.contact_link_url
        expect(page3.contact_link_name).not_to eq group1.contact_link_name
      end
    end

    context "empty to non-empty" do
      let(:group_attributes) do
        {
          contact_email: "",
          contact_tel: "",
          contact_fax: "",
          contact_link_url: "",
          contact_link_name: "",
          main_state: "main"
        }
      end
      let!(:group1) { create(:revision_new_group, contact_groups: [ group_attributes ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination) do
        {
          name: group1.name,
          order: "",
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id,
          ldap_dn: ""
        }
      end
      let!(:changeset) do
        create(
          :move_changeset, revision_id: revision.id, source: group1, destinations: [ destination.stringify_keys ]
        )
      end
      # group1 と同じ情報が連絡先にセットされているページ
      let!(:page1) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: group1.contact_email,
          contact_tel: group1.contact_tel,
          contact_fax: group1.contact_fax,
          contact_link_url: group1.contact_link_url,
          contact_link_name: group1.contact_link_name
        )
      end
      # 連絡先に異なる情報がセットされているページ
      let!(:page2) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id
        )
      end

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        group1.reload
        expect(group1.contact_email).to eq destination[:contact_email]
        expect(group1.contact_tel).to eq destination[:contact_tel]
        expect(group1.contact_fax).to eq destination[:contact_fax]
        expect(group1.contact_link_url).to eq destination[:contact_link_url]
        expect(group1.contact_link_name).to eq destination[:contact_link_name]

        # check page
        page1.reload
        expect(page1.group_ids).to eq [ group1.id ]
        expect(page1.contact_group_id).to eq group1.id
        expect(page1.contact_email).to eq group1.contact_email
        expect(page1.contact_tel).to eq group1.contact_tel
        expect(page1.contact_fax).to eq group1.contact_fax
        expect(page1.contact_link_url).to eq group1.contact_link_url
        expect(page1.contact_link_name).to eq group1.contact_link_name

        page2.reload
        expect(page2.group_ids).to eq [ group1.id ]
        expect(page2.contact_group_id).to eq group1.id
        expect(page2.contact_email).not_to eq group1.contact_email
        expect(page2.contact_tel).not_to eq group1.contact_tel
        expect(page2.contact_fax).not_to eq group1.contact_fax
        expect(page2.contact_link_url).not_to eq group1.contact_link_url
        expect(page2.contact_link_name).not_to eq group1.contact_link_name
      end
    end
  end

  context 'with forced_overwrite' do
    let(:job_opts) { { 'newly_created_group_to_site' => 'add', 'forced_overwrite' => true } }

    context "non-empty to non-empty" do
      let(:group_attributes) do
        {
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id,
          main_state: "main"
        }
      end
      let!(:group1) { create(:revision_new_group, contact_groups: [ group_attributes ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination) do
        {
          name: group1.name,
          order: "",
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id,
          ldap_dn: ""
        }
      end
      let!(:changeset) do
        create(
          :move_changeset, revision_id: revision.id, source: group1, destinations: [ destination.stringify_keys ]
        )
      end
      # group1 と同じ情報が連絡先にセットされているページ
      let!(:page1) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: group1.contact_email,
          contact_tel: group1.contact_tel,
          contact_fax: group1.contact_fax,
          contact_link_url: group1.contact_link_url,
          contact_link_name: group1.contact_link_name
        )
      end
      # 連絡先が空のページ
      let!(:page2) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: "",
          contact_tel: "",
          contact_fax: "",
          contact_link_url: "",
          contact_link_name: ""
        )
      end
      # 連絡先に異なる情報がセットされているページ
      let!(:page3) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id
        )
      end

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        group1.reload
        expect(group1.contact_email).to eq destination[:contact_email]
        expect(group1.contact_tel).to eq destination[:contact_tel]
        expect(group1.contact_fax).to eq destination[:contact_fax]
        expect(group1.contact_link_url).to eq destination[:contact_link_url]
        expect(group1.contact_link_name).to eq destination[:contact_link_name]

        # check page
        page1.reload
        expect(page1.group_ids).to eq [ group1.id ]
        expect(page1.contact_group_id).to eq group1.id
        expect(page1.contact_email).to eq group1.contact_email
        expect(page1.contact_tel).to eq group1.contact_tel
        expect(page1.contact_fax).to eq group1.contact_fax
        expect(page1.contact_link_url).to eq group1.contact_link_url
        expect(page1.contact_link_name).to eq group1.contact_link_name

        page2.reload
        expect(page2.group_ids).to eq [ group1.id ]
        expect(page2.contact_group_id).to eq group1.id
        expect(page2.contact_email).to eq group1.contact_email
        expect(page2.contact_tel).to eq group1.contact_tel
        expect(page2.contact_fax).to eq group1.contact_fax
        expect(page2.contact_link_url).to eq group1.contact_link_url
        expect(page2.contact_link_name).to eq group1.contact_link_name

        page3.reload
        expect(page3.group_ids).to eq [ group1.id ]
        expect(page3.contact_group_id).to eq group1.id
        expect(page3.contact_email).to eq group1.contact_email
        expect(page3.contact_tel).to eq group1.contact_tel
        expect(page3.contact_fax).to eq group1.contact_fax
        expect(page3.contact_link_url).to eq group1.contact_link_url
        expect(page3.contact_link_name).to eq group1.contact_link_name
      end
    end

    context "empty to non-empty" do
      let(:group_attributes) do
        {
          contact_email: "",
          contact_tel: "",
          contact_fax: "",
          contact_link_url: "",
          contact_link_name: "",
          main_state: "main"
        }
      end
      let!(:group1) { create(:revision_new_group, contact_groups: [ group_attributes ]) }
      let!(:revision) { create(:revision, site_id: site.id) }
      let(:destination) do
        {
          name: group1.name,
          order: "",
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id,
          ldap_dn: ""
        }
      end
      let!(:changeset) do
        create(
          :move_changeset, revision_id: revision.id, source: group1, destinations: [ destination.stringify_keys ]
        )
      end
      # group1 と同じ情報が連絡先にセットされているページ
      let!(:page1) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: group1.contact_email,
          contact_tel: group1.contact_tel,
          contact_fax: group1.contact_fax,
          contact_link_url: group1.contact_link_url,
          contact_link_name: group1.contact_link_name
        )
      end
      # 連絡先に異なる情報がセットされているページ
      let!(:page2) do
        create(
          :revision_page, cur_site: site, group: group1, filename: nil,
          contact_email: unique_email,
          contact_tel: unique_tel,
          contact_fax: unique_tel,
          contact_link_url: "/#{unique_id}/",
          contact_link_name: unique_id
        )
      end

      it do
        # execute
        job = described_class.bind(site_id: site, task_id: task)
        expect { job.perform_now(revision.name, job_opts) }.to output(include("[移動] 成功: 1, 失敗: 0\n")).to_stdout

        # check for job was succeeded
        expect(Job::Log.count).to eq 1
        Job::Log.first.tap do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        group1.reload
        expect(group1.contact_email).to eq destination[:contact_email]
        expect(group1.contact_tel).to eq destination[:contact_tel]
        expect(group1.contact_fax).to eq destination[:contact_fax]
        expect(group1.contact_link_url).to eq destination[:contact_link_url]
        expect(group1.contact_link_name).to eq destination[:contact_link_name]

        # check page
        page1.reload
        expect(page1.group_ids).to eq [ group1.id ]
        expect(page1.contact_group_id).to eq group1.id
        expect(page1.contact_email).to eq group1.contact_email
        expect(page1.contact_tel).to eq group1.contact_tel
        expect(page1.contact_fax).to eq group1.contact_fax
        expect(page1.contact_link_url).to eq group1.contact_link_url
        expect(page1.contact_link_name).to eq group1.contact_link_name

        page2.reload
        expect(page2.group_ids).to eq [ group1.id ]
        expect(page2.contact_group_id).to eq group1.id
        expect(page2.contact_email).to eq group1.contact_email
        expect(page2.contact_tel).to eq group1.contact_tel
        expect(page2.contact_fax).to eq group1.contact_fax
        expect(page2.contact_link_url).to eq group1.contact_link_url
        expect(page2.contact_link_name).to eq group1.contact_link_name
      end
    end
  end
end
