require 'spec_helper'

describe Fs, tmpdir: true do
  let(:filesystem) do
    Class.new do
      include ::Fs::File
    end
  end

  let(:grid_fs) do
    Class.new do
      include ::Fs::GridFs
    end
  end

  let(:data) { ::File.binread("#{Rails.root}/spec/fixtures/ss/logo.png") }

  before do
    grid_fs.binwrite("#{Rails.root}/spec/fixtures/ss/logo.png", data)
  end

  describe '.mode' do
    it do
      expect(filesystem.mode).to eq :file
      expect(grid_fs.mode).to eq :grid_fs
    end
  end

  describe '.exists?' do
    it do
      # full path
      expect(filesystem.exists?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_truthy
      expect(grid_fs.exists?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_truthy
      # not exists
      expect(filesystem.exists?("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to be_falsey
      expect(grid_fs.exists?("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to be_falsey
    end

    it do
      # relative path
      expect(filesystem.exists?("spec/fixtures/ss/logo.png")).to be_truthy
      expect(grid_fs.exists?("spec/fixtures/ss/logo.png")).to be_truthy
      # not exists
      expect(filesystem.exists?("spec/fixtures/ss/#{unique_id}.png")).to be_falsey
      expect(grid_fs.exists?("spec/fixtures/ss/#{unique_id}.png")).to be_falsey
    end
  end

  describe '.file?' do
    it do
      # full path
      expect(filesystem.file?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_truthy
      expect(grid_fs.file?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_truthy
      # not exists
      expect(filesystem.file?("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to be_falsey
      expect(grid_fs.file?("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to be_falsey
    end

    it do
      # relative path
      expect(filesystem.file?("spec/fixtures/ss/logo.png")).to be_truthy
      expect(grid_fs.file?("spec/fixtures/ss/logo.png")).to be_truthy
      # not exists
      expect(filesystem.file?("spec/fixtures/ss/#{unique_id}.png")).to be_falsey
      expect(grid_fs.file?("spec/fixtures/ss/#{unique_id}.png")).to be_falsey
    end
  end

  describe '.directory?' do
    it do
      # full path
      expect(filesystem.directory?("#{Rails.root}/spec/fixtures/ss")).to be_truthy
      expect(grid_fs.directory?("#{Rails.root}/spec/fixtures/ss")).to be_truthy
      expect(filesystem.directory?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_falsey
      expect(grid_fs.directory?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_falsey
      # not exists
      expect(filesystem.directory?("#{Rails.root}/spec/fixtures/#{unique_id}")).to be_falsey
      expect(grid_fs.directory?("#{Rails.root}/spec/fixtures/#{unique_id}")).to be_falsey
    end

    it do
      # relative path
      expect(filesystem.directory?("spec/fixtures/ss")).to be_truthy
      expect(grid_fs.directory?("spec/fixtures/ss")).to be_truthy
      expect(filesystem.directory?("spec/fixtures/ss/logo.png")).to be_falsey
      expect(grid_fs.directory?("spec/fixtures/ss/logo.png")).to be_falsey
      # not exists
      expect(filesystem.directory?("spec/fixtures/#{unique_id}")).to be_falsey
      expect(grid_fs.directory?("spec/fixtures/#{unique_id}")).to be_falsey
    end
  end

  describe '.binread' do
    it do
      # full path
      expect(filesystem.binread("#{Rails.root}/spec/fixtures/ss/logo.png").hash).to eq data.hash
      expect(grid_fs.binread("#{Rails.root}/spec/fixtures/ss/logo.png").hash).to eq data.hash
      # not exists
      expect { filesystem.binread("#{Rails.root}/spec/fixtures/#{unique_id}") }.to raise_error Errno::ENOENT
      expect { grid_fs.binread("#{Rails.root}/spec/fixtures/#{unique_id}") }.to raise_error ::Fs::GridFs::FileNotFoundError
    end

    it do
      # relative path
      expect(filesystem.binread("spec/fixtures/ss/logo.png").hash).to eq data.hash
      expect(grid_fs.binread("spec/fixtures/ss/logo.png").hash).to eq data.hash
      # not exists
      expect { filesystem.binread("spec/fixtures/#{unique_id}") }.to raise_error Errno::ENOENT
      expect { grid_fs.binread("spec/fixtures/#{unique_id}") }.to raise_error ::Fs::GridFs::FileNotFoundError
    end
  end

  describe '.binwrite' do
    let(:tmp_dir) { "#{tmpdir}/spec/fs" }

    before do
      ::FileUtils.mkdir_p(tmp_dir)
    end

    it do
      # full path
      expect(filesystem.binwrite("#{tmpdir}/spec/fs/logo.png", data)).to eq data.length
      expect(grid_fs.binwrite("#{tmpdir}/spec/fs/logo.png", data)).to eq data.length
      # write nil
      expect(filesystem.binwrite("#{tmpdir}/spec/fs/logo.png", nil)).to eq 0
      expect(grid_fs.binwrite("#{tmpdir}/spec/fs/logo.png", nil)).to eq 0
      # write empty
      expect(filesystem.binwrite("#{tmpdir}/spec/fs/logo.png", '')).to eq 0
      expect(grid_fs.binwrite("#{tmpdir}/spec/fs/logo.png", '')).to eq 0
    end
  end

  describe '.size' do
    it do
      # full path
      expect(filesystem.size("#{Rails.root}/spec/fixtures/ss/logo.png")).to eq data.length
      expect(grid_fs.size("#{Rails.root}/spec/fixtures/ss/logo.png")).to eq data.length
      # not exists
      expect { filesystem.size("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png") }.to raise_error Errno::ENOENT
      expect { grid_fs.size("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png") }.to raise_error ::Fs::GridFs::FileNotFoundError
    end

    it do
      # relative path
      expect(filesystem.size("spec/fixtures/ss/logo.png")).to eq data.length
      expect(grid_fs.size("spec/fixtures/ss/logo.png")).to eq data.length
      # not exists
      expect { filesystem.size("spec/fixtures/ss/#{unique_id}.png") }.to raise_error Errno::ENOENT
      expect { grid_fs.size("spec/fixtures/ss/#{unique_id}.png") }.to raise_error ::Fs::GridFs::FileNotFoundError
    end
  end

  describe '.content_type' do
    it do
      # full path
      expect(filesystem.content_type("#{Rails.root}/spec/fixtures/ss/logo.png")).to eq 'image/png'
      expect(grid_fs.content_type("#{Rails.root}/spec/fixtures/ss/logo.png")).to eq 'image/png'
      # not exists
      expect(filesystem.content_type("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to eq 'image/png'
      expect(grid_fs.content_type("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to eq 'image/png'
    end

    it do
      # relative path
      expect(filesystem.content_type("spec/fixtures/ss/logo.png")).to eq 'image/png'
      expect(grid_fs.content_type("spec/fixtures/ss/logo.png")).to eq 'image/png'
      # not exists
      expect(filesystem.content_type("spec/fixtures/ss/#{unique_id}.png")).to eq 'image/png'
      expect(grid_fs.content_type("spec/fixtures/ss/#{unique_id}.png")).to eq 'image/png'
    end
  end

  describe '.mkdir_p' do
    it do
      # full path
      expect(filesystem.mkdir_p("#{tmpdir}/spec/fixtures/#{unique_id}")).to be_truthy
      expect(grid_fs.mkdir_p("#{tmpdir}/spec/fixtures/#{unique_id}")).to be_truthy
    end
  end

  describe '.mv' do
    let(:tmp_file) { "#{tmpdir}/spec/fs/logo.png" }

    before do
      ::FileUtils.mkdir_p(::File.dirname(tmp_file))
      ::File.binwrite(tmp_file, data)

      grid_fs.binwrite("#{tmpdir}/spec/fs/logo.png", data)
    end

    it do
      expect(filesystem.mv("#{tmpdir}/spec/fs/logo.png", "#{tmpdir}/spec/fs/logo1.png")).to eq 0
      expect(grid_fs.mv("#{tmpdir}/spec/fs/logo.png", "#{tmpdir}/spec/fs/logo1.png")).to eq 0
      # not exists
      expect { filesystem.mv("#{tmpdir}/spec/fs/logo2.png", "#{tmpdir}/spec/fs/logo3.png") }.to \
        raise_error Errno::ENOENT
      expect { grid_fs.mv("#{tmpdir}/spec/fs/logo2.png", "#{tmpdir}/spec/fs/logo3.png") }.to \
        raise_error ::Fs::GridFs::FileNotFoundError
      # move directory
      expect(filesystem.mv("#{tmpdir}/spec/fs", "#{tmpdir}/spec/fs2")).to eq 0
      expect(grid_fs.mv("#{tmpdir}/spec/fs", "#{tmpdir}/spec/fs2")).to eq 0
    end
  end

  describe '.rm_rf' do
    let(:tmp_file) { "#{tmpdir}/spec/fs/logo.png" }

    before do
      ::FileUtils.mkdir_p(::File.dirname(tmp_file))
      ::File.binwrite(tmp_file, data)

      grid_fs.binwrite("#{tmpdir}/spec/fs/logo.png", data)
    end

    it do
      expect(filesystem.rm_rf("#{tmpdir}/spec/fs/logo.png")).to eq [ "#{tmpdir}/spec/fs/logo.png" ]
      expect(grid_fs.rm_rf("#{tmpdir}/spec/fs/logo.png")).to eq [ "#{tmpdir}/spec/fs/logo.png" ]
    end

    it do
      # not exists
      expect(filesystem.rm_rf("#{tmpdir}/spec/fs/logo2.png")).to eq [ "#{tmpdir}/spec/fs/logo2.png" ]
      expect(grid_fs.rm_rf("#{tmpdir}/spec/fs/logo2.png")).to eq [ "#{tmpdir}/spec/fs/logo2.png" ]
    end

    it do
      # remove directory
      expect(filesystem.rm_rf("#{tmpdir}/spec/fs")).to eq [ "#{tmpdir}/spec/fs" ]
      expect(grid_fs.rm_rf("#{tmpdir}/spec/fs")).to eq [ "#{tmpdir}/spec/fs" ]
    end
  end

  describe '.glob' do
    let(:tmp_file) { "#{tmpdir}/spec/fs/logo.png" }

    before do
      ::FileUtils.mkdir_p(::File.dirname(tmp_file))
      ::File.binwrite(tmp_file, data)

      grid_fs.binwrite("#{tmpdir}/spec/fs/logo.png", data)
    end

    it do
      expect(filesystem.glob("#{tmpdir}/spec/fs/*")).to eq [ "#{tmpdir}/spec/fs/logo.png" ]
      expect(filesystem.glob("#{tmpdir}/spec/**/*")).to eq [ "#{tmpdir}/spec/fs", "#{tmpdir}/spec/fs/logo.png" ]

      expect(grid_fs.glob("#{tmpdir}/spec/fs/*")).to eq [ "#{tmpdir}/spec/fs/logo.png"[1..-1] ]
      expect(grid_fs.glob("#{tmpdir}/spec/**/*")).to eq [ "#{tmpdir}/spec/fs/logo.png"[1..-1] ]
    end
  end
end
