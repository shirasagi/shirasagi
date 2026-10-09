require 'spec_helper'

describe Gws::Tabular::FormRefreshJob, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  describe '#perform' do
    let!(:space) { create :gws_tabular_space, cur_site: site }
    let!(:form) { create :gws_tabular_form, cur_site: site, cur_space: space, state: 'publishing', revision: 1 }
    let!(:column1) do
      create(:gws_tabular_column_text_field, cur_site: site, cur_form: form, input_type: "single", required: "optional")
    end

    before do
      Gws::Tabular::FormPublishJob.bind(site_id: site, user_id: user).perform_now(form.id.to_s)

      expect(Gws::Job::Log.all.count).to eq 1
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      after_form = Gws::Tabular::Form.find(form.id)
      expect(after_form.state).to eq 'public'

      generator = Gws::Tabular::File::Generator.new(form_release: after_form.current_release)
      expect(File.exist?(generator.target_file_path)).to be_truthy

      save_mtime = File.mtime(generator.target_file_path)
      File.open(generator.target_file_path, "at") do |f|
        f.puts "`touch '#{SS::Application.private_root}/hacked'`"
      end
      File.utime(Time.zone.now.to_time, save_mtime, generator.target_file_path)

      Gws::Job::Log.all.destroy_all
    end

    it do
      described_class.bind(site_id: site).perform_now

      expect(Gws::Job::Log.all.count).to eq 1
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      after_form = Gws::Tabular::Form.find(form.id)
      generator = Gws::Tabular::File::Generator.new(form_release: after_form.current_release)
      expect(File.exist?(generator.target_file_path)).to be_truthy
      class_def = File.read(generator.target_file_path)
      expect(class_def.include?("hacked")).to be_falsey
    end
  end
end
