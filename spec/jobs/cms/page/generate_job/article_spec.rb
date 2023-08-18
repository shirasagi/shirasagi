require 'spec_helper'

describe Cms::Page::GenerateJob, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:layout) { create_cms_layout }
  let(:node) { create :article_node_page, cur_site: cms_site, layout_id: layout.id }

  let!(:page1) do
    create(:article_page,
      cur_site: cms_site,
      cur_user: user,
      cur_node: node,
      state: 'public',
      layout_id: layout.id,
      file_ids: [ss_file1.id]
    )
  end
  let!(:page2) do
    create(:article_page,
      cur_site: cms_site,
      cur_user: user,
      cur_node: node,
      state: 'public',
      layout_id: layout.id
    )
  end
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let!(:column1) do
    create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 1, file_type: "image")
  end
  let!(:column2) do
    create(:cms_column_free, cur_site: site, cur_form: form, order: 2)
  end

  let!(:ss_file1) { create :ss_file, site: site, user: user, state: 'public' }
  let!(:ss_file2) { create :ss_file, site: site, user: user, state: 'public' }
  let!(:ss_file3) { create :ss_file, site: site, user: user, state: 'public' }
  let!(:ss_file4) { create :ss_file, site: site, user: user, state: 'public' }

  before do
    node.st_form_ids = [ form.id ]
    node.save!

    page2.form = form
    page2.column_values = [
      column1.value_type.new(column: column1, file_id: ss_file2.id, file_label: ss_file2.humanized_name),
      column2.value_type.new(column: column2, value: unique_id * 2, file_ids: [ ss_file3.id, ss_file4.id ])
    ]
    page2.save!

    Cms::Task.create!(site_id: site.id, node_id: nil, name: 'cms:generate_pages', state: 'ready')
    Cms::Task.create!(site_id: site.id, node_id: node.id, name: 'cms:generate_pages', state: 'ready')
  end

  describe "#perform without node" do
    before do
      Fs.rm_rf node.path

      Fs.rm_rf page1.path
      Fs.rm_rf ss_file1.public_path

      Fs.rm_rf page2.path
      Fs.rm_rf ss_file2.public_path
      Fs.rm_rf ss_file3.public_path
      Fs.rm_rf ss_file4.public_path

      expect { described_class.bind(site_id: site.id).perform_now }.to output(include(page1.url, page2.url)).to_stdout
    end

    it do
      expect(File.size(page1.path)).to be > 0
      expect(File.size(ss_file1.public_path)).to be > 0

      expect(File.size(page2.path)).to be > 0
      expect(File.size(ss_file2.public_path)).to be > 0
      expect(File.size(ss_file3.public_path)).to be > 0
      expect(File.size(ss_file4.public_path)).to be > 0
      expect(Cms::Task.count).to eq 2
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'completed'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 2
        expect(task.current_count).to eq 2
        expect(task.logs).to include(include(page1.filename))
        expect(task.node_id).to be_nil
        # logs are saved in a file
        expect(::File.size(task.log_file_path)).to be > 0
        # and there are no `logs` field
        expect(task[:logs]).to be_nil
      end
      Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'ready'
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end

  describe "#perform with node" do
    before do
      Fs.rm_rf node.path

      Fs.rm_rf page1.path
      Fs.rm_rf ss_file1.public_path

      Fs.rm_rf page2.path
      Fs.rm_rf ss_file2.public_path
      Fs.rm_rf ss_file3.public_path
      Fs.rm_rf ss_file4.public_path

      expect { described_class.bind(site_id: site.id, node_id: node.id).perform_now }.to \
        output(include(page1.url, page2.url)).to_stdout
    end

    it do
      expect(File.size(page1.path)).to be > 0
      expect(File.size(ss_file1.public_path)).to be > 0

      expect(File.size(page2.path)).to be > 0
      expect(File.size(ss_file2.public_path)).to be > 0
      expect(File.size(ss_file3.public_path)).to be > 0
      expect(File.size(ss_file4.public_path)).to be > 0

      expect(Cms::Task.count).to eq 2
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'ready'
      end
      Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'completed'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 2
        expect(task.current_count).to eq 2
        expect(task.logs).to include(include(page1.filename))
        expect(task.node_id).to eq node.id
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end

  describe "#perform with generate_lock" do
    before do
      @save_config = SS.config.cms.generate_lock
      SS.config.replace_value_at(:cms, 'generate_lock', { 'disable' => false, 'options' => ['1.hour'] })
      site.set(generate_lock_until: Time.zone.now + 1.hour)

      Fs.rm_rf node.path

      Fs.rm_rf page1.path
      Fs.rm_rf ss_file1.public_path

      Fs.rm_rf page2.path
      Fs.rm_rf ss_file2.public_path
      Fs.rm_rf ss_file3.public_path
      Fs.rm_rf ss_file4.public_path

      expect { described_class.bind(site_id: site.id).perform_now }.to \
        output(include(I18n.t("mongoid.attributes.ss/addon/generate_lock.generate_locked"))).to_stdout
    end

    after do
      SS.config.replace_value_at(:cms, 'generate_lock', @save_config)
    end

    it do
      expect(File.exist?(page1.path)).to be_falsey
      expect(File.exist?(ss_file1.public_path)).to be_falsey

      expect(File.exist?(page2.path)).to be_falsey
      expect(File.exist?(ss_file2.public_path)).to be_falsey
      expect(File.exist?(ss_file3.public_path)).to be_falsey
      expect(File.exist?(ss_file4.public_path)).to be_falsey

      expect(Cms::Task.count).to eq 2
      Cms::Task.where(site_id: site.id, node_id: nil, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'completed'
        expect(task.started).not_to be_nil
        expect(task.closed).not_to be_nil
        expect(task.total_count).to eq 0
        expect(task.current_count).to eq 0
        expect(task.logs).not_to include(include(page1.filename))
        expect(task.node_id).to be_nil
        # logs are saved in a file
        expect(::File.size(task.log_file_path)).to be > 0
        # and there are no `logs` field
        expect(task[:logs]).to be_nil
      end
      Cms::Task.where(site_id: site.id, node_id: node.id, name: 'cms:generate_pages').first.tap do |task|
        expect(task.state).to eq 'ready'
      end

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(include(I18n.t('mongoid.attributes.ss/addon/generate_lock.generate_locked')))
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end

  describe "fist /fs is not restricted, and then /fs is restricted" do
    before do
      Fs.rm_rf node.path

      Fs.rm_rf page1.path
      Fs.rm_rf ss_file1.public_path

      Fs.rm_rf page2.path
      Fs.rm_rf ss_file2.public_path
      Fs.rm_rf ss_file3.public_path
      Fs.rm_rf ss_file4.public_path
    end

    it do
      expect { described_class.bind(site_id: site.id).perform_now }.to output(include(page1.url, page2.url)).to_stdout

      expect(File.size(page1.path)).to be > 0
      expect(File.size(ss_file1.public_path)).to be > 0
      expect(File.size(page2.path)).to be > 0
      expect(File.size(ss_file2.public_path)).to be > 0
      expect(File.size(ss_file3.public_path)).to be > 0
      expect(File.size(ss_file4.public_path)).to be > 0

      site.file_fs_access_restriction_state = "enabled"
      site.save!

      expect { described_class.bind(site_id: site.id).perform_now }.not_to output(include(page1.url, page2.url)).to_stdout

      expect(File.size(page1.path)).to be > 0
      expect(File.exist?(ss_file1.public_path)).to be_falsey
      expect(File.size(page2.path)).to be > 0
      expect(File.exist?(ss_file2.public_path)).to be_falsey
      expect(File.exist?(ss_file3.public_path)).to be_falsey
      expect(File.exist?(ss_file4.public_path)).to be_falsey
    end
  end
end
