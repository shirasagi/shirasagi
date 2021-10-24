require 'spec_helper'

describe SS::UploadPolicy, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }

  before do
    SS.current_site = nil
    SS.current_user = nil
    SS.current_organization = nil
  end

  describe "methods" do
    it "sanitizer_input_path" do
      file = SS::File.new(name: 'example.txt')
      result = file.sanitizer_input_path.starts_with?("#{Rails.root}/#{SS.config.ss.sanitizer_input}/")
      expect(result).to be_truthy

      sanitizer_input_basename = ::File.basename(file.sanitizer_input_path)
      result = sanitizer_input_basename.starts_with?("#{SS.config.ss.sanitizer_file_prefix}_")
      expect(result).to be_truthy
    end
  end

  context "restore zip" do
    let(:zip_source) { "#{Rails.root}/spec/fixtures/ss/file/ss_file_1_1635072302_1000_sanitized.zip" }
    let(:zip_path) { "#{root_dir}/ss_file_1_1635072302_1000_sanitized.zip" }

    before do
      ::Fs.mkdir_p(root_dir)
      FileUtils.cp(zip_source, zip_path)
    end
    after { FileUtils.rm(zip_path) }

    it "restore zip" do
      restored_paths = [
        'import/dirname/image.png',
        'import/dirname/test.html',
        'import/image.png',
        'import/test.html'
      ]

      SS::UploadPolicy.sanitizer_rename_zip(zip_path)

      Zip::File.open(zip_path) do |zip_file|
        zip_file.entries.sort_by(&:name).each do |entry|
          next if entry.ftype == :directory
          expect(restored_paths.include?(entry.name)).to be_truthy
        end
      end
    end
  end

  context "empty setting" do
    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, nil)
    end

    after do
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    it do
      expect(SS::UploadPolicy.upload_policy).to be_nil

      SS.current_organization = user.organization
      expect(SS::UploadPolicy.upload_policy).to be_nil

      SS.current_organization.upload_policy = 'restricted'
      expect(SS::UploadPolicy.upload_policy).to be_nil

      SS.current_site = cms_site
      expect(SS::UploadPolicy.upload_policy).to be_nil

      SS.current_site.upload_policy = 'restricted'
      expect(SS::UploadPolicy.upload_policy).to be_nil
    end
  end

  context "sanitizer setting" do
    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
    end

    after do
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    it do
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_organization = user.organization
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_organization.upload_policy = 'sanitizer'
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_organization.upload_policy = 'restricted'
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'

      SS.current_site = site
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_site.upload_policy = 'sanitizer'
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_site.upload_policy = 'restricted'
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'
    end
  end

  context "restricted setting" do
    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'restricted')
    end

    after do
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    it do
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'

      SS.current_organization = user.organization
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'

      SS.current_organization.upload_policy = 'sanitizer'
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_organization.upload_policy = 'restricted'
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'

      SS.current_site = site
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'

      SS.current_site.upload_policy = 'sanitizer'
      expect(SS::UploadPolicy.upload_policy).to eq 'sanitizer'

      SS.current_site.upload_policy = 'restricted'
      expect(SS::UploadPolicy.upload_policy).to eq 'restricted'
    end
  end
end
