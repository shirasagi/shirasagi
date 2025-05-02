require 'spec_helper'

describe Fs do
  let(:data) { ::File.binread("#{Rails.root}/spec/fixtures/ss/logo.png") }

  describe '.mode' do
    it do
      expect(Fs.mode).to eq :file
    end
  end

  describe '.exist?' do
    it do
      # full path
      expect(Fs.exist?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_truthy
      # not exist
      expect(Fs.exist?("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to be_falsey
    end

    it do
      # relative path
      expect(Fs.exist?("spec/fixtures/ss/logo.png")).to be_truthy
      # not exist
      expect(Fs.exist?("spec/fixtures/ss/#{unique_id}.png")).to be_falsey
    end
  end

  describe '.file?' do
    it do
      # full path
      expect(Fs.file?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_truthy
      # not exist
      expect(Fs.file?("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to be_falsey
    end

    it do
      # relative path
      expect(Fs.file?("spec/fixtures/ss/logo.png")).to be_truthy
      # not exist
      expect(Fs.file?("spec/fixtures/ss/#{unique_id}.png")).to be_falsey
    end
  end

  describe '.directory?' do
    it do
      # full path
      expect(Fs.directory?("#{Rails.root}/spec/fixtures/ss")).to be_truthy
      expect(Fs.directory?("#{Rails.root}/spec/fixtures/ss/logo.png")).to be_falsey
      # not exist
      expect(Fs.directory?("#{Rails.root}/spec/fixtures/#{unique_id}")).to be_falsey
    end

    it do
      # relative path
      expect(Fs.directory?("spec/fixtures/ss")).to be_truthy
      expect(Fs.directory?("spec/fixtures/ss/logo.png")).to be_falsey
      # not exist
      expect(Fs.directory?("spec/fixtures/#{unique_id}")).to be_falsey
    end
  end

  describe '.binread' do
    it do
      # full path
      expect(Fs.binread("#{Rails.root}/spec/fixtures/ss/logo.png").hash).to eq data.hash
      # not exist
      expect { Fs.binread("#{Rails.root}/spec/fixtures/#{unique_id}") }.to raise_error Errno::ENOENT
    end

    it do
      # relative path
      expect(Fs.binread("spec/fixtures/ss/logo.png").hash).to eq data.hash
      # not exist
      expect { Fs.binread("spec/fixtures/#{unique_id}") }.to raise_error Errno::ENOENT
    end
  end

  describe '.binwrite' do
    let(:tmp_dir) { "#{tmpdir}/spec/fs" }

    before do
      ::FileUtils.mkdir_p(tmp_dir)
    end

    it do
      # full path
      expect(Fs.binwrite("#{tmpdir}/spec/fs/logo.png", data)).to eq data.length
      # write nil
      expect(Fs.binwrite("#{tmpdir}/spec/fs/logo.png", nil)).to eq 0
      # write empty
      expect(Fs.binwrite("#{tmpdir}/spec/fs/logo.png", '')).to eq 0
    end
  end

  describe '.size' do
    it do
      # full path
      expect(Fs.size("#{Rails.root}/spec/fixtures/ss/logo.png")).to eq data.length
      # not exist
      expect { Fs.size("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png") }.to raise_error Errno::ENOENT
    end

    it do
      # relative path
      expect(Fs.size("spec/fixtures/ss/logo.png")).to eq data.length
      # not exist
      expect { Fs.size("spec/fixtures/ss/#{unique_id}.png") }.to raise_error Errno::ENOENT
    end
  end

  describe '.content_type' do
    it do
      # full path
      expect(Fs.content_type("#{Rails.root}/spec/fixtures/ss/logo.png")).to eq 'image/png'
      # not exist
      expect(Fs.content_type("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png")).to eq 'image/png'
    end

    it do
      # relative path
      expect(Fs.content_type("spec/fixtures/ss/logo.png")).to eq 'image/png'
      # not exist
      expect(Fs.content_type("spec/fixtures/ss/#{unique_id}.png")).to eq 'image/png'
    end
  end

  describe '.mkdir_p' do
    it do
      # full path
      expect(Fs.mkdir_p("#{tmpdir}/spec/fixtures/#{unique_id}")).to be_truthy
    end
  end

  describe '.mv' do
    let(:tmp_file) { "#{tmpdir}/spec/fs/logo.png" }

    before do
      ::FileUtils.mkdir_p(::File.dirname(tmp_file))
      ::File.binwrite(tmp_file, data)
    end

    it do
      expect(Fs.mv("#{tmpdir}/spec/fs/logo.png", "#{tmpdir}/spec/fs/logo1.png")).to eq 0
      # not exist
      expect { Fs.mv("#{tmpdir}/spec/fs/logo2.png", "#{tmpdir}/spec/fs/logo3.png") }.to \
        raise_error Errno::ENOENT
      # move directory
      expect(Fs.mv("#{tmpdir}/spec/fs", "#{tmpdir}/spec/fs2")).to eq 0
    end
  end

  describe '.rm_rf' do
    let(:tmp_file) { "#{tmpdir}/spec/fs/logo.png" }

    before do
      ::FileUtils.mkdir_p(::File.dirname(tmp_file))
      ::File.binwrite(tmp_file, data)
    end

    it do
      expect(Fs.rm_rf("#{tmpdir}/spec/fs/logo.png")).to eq [ "#{tmpdir}/spec/fs/logo.png" ]
    end

    it do
      # not exist
      expect(Fs.rm_rf("#{tmpdir}/spec/fs/logo2.png")).to eq [ "#{tmpdir}/spec/fs/logo2.png" ]
    end

    it do
      # remove directory
      expect(Fs.rm_rf("#{tmpdir}/spec/fs")).to eq [ "#{tmpdir}/spec/fs" ]
    end
  end

  describe '.glob' do
    let(:tmp_file) { "#{tmpdir}/spec/fs/logo.png" }

    before do
      ::FileUtils.mkdir_p(::File.dirname(tmp_file))
      ::File.binwrite(tmp_file, data)
    end

    it do
      expect(Fs.glob("#{tmpdir}/spec/fs/*")).to eq [ "#{tmpdir}/spec/fs/logo.png" ]
      expect(Fs.glob("#{tmpdir}/spec/**/*")).to eq [ "#{tmpdir}/spec/fs", "#{tmpdir}/spec/fs/logo.png" ]
    end
  end

  describe '.same_data?' do
    it do
      expect(Fs.same_data?("#{Rails.root}/spec/fixtures/ss/logo.png", data)).to be_truthy

      expect(Fs.same_data?("#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif", data)).to be_falsey
      expect(Fs.same_data?("#{Rails.root}/spec/fixtures/ss/#{unique_id}.png", data)).to be_falsey
    end
  end

  describe ".write_data_if_modified" do
    context "when binary is given" do
      it do
        path = "#{tmpdir}/spec/fs/#{unique_id}.png"

        expect(Fs.exist?(path)).to be_falsey
        expect(Fs.write_data_if_modified(path, data)).to be_truthy
        expect(Fs.exist?(path)).to be_truthy

        # 2nd attempt
        expect(Fs.write_data_if_modified(path, data)).to be_falsey
        expect(Fs.exist?(path)).to be_truthy
      end
    end

    context "when text is given" do
      it do
        data = "<html></html>"
        path = "#{tmpdir}/spec/fs/#{unique_id}.html"

        expect(Fs.exist?(path)).to be_falsey
        expect(Fs.write_data_if_modified(path, data)).to be_truthy
        expect(Fs.exist?(path)).to be_truthy

        # 2nd attempt
        expect(Fs.write_data_if_modified(path, data)).to be_falsey
        expect(Fs.exist?(path)).to be_truthy
      end
    end
  end

  describe '.head_lines' do
    context "when nil is given as path" do
      it do
        expect(Fs.head_lines(nil)).to eq []
      end
    end

    context "when nil is given as path" do
      let(:tmp_file_path) do
        tmpfile do |f|
          3.times do
            f.puts ss_japanese_text
          end
        end
      end

      it do
        expect(Fs.head_lines(tmp_file_path)).to have(3).items
        expect(Fs.head_lines(tmp_file_path, limit: 2)).to have(2).items
        expect { ss_japanese_text + Fs.head_lines(tmp_file_path, limit: 2).join }.not_to raise_error
      end
    end
  end

  describe '.tail_lines' do
    context "when nil is given as path" do
      it do
        expect(Fs.tail_lines(nil)).to be_blank
      end
    end

    context "random UTF-8 is given" do
      let(:path) do
        # 末端が不利な位置にあっても正しく末尾行を取得できることを確認するためのデータ
        # さまざまな乱数シードを用いて 10 連続で成功することを確認済み
        tmpfile do |file|
          file.write "a" * rand(1..3)
          file.write Array.new(rand(1..3)) { ss_japanese_text }.join + "\n" while file.size < 1024
        end
      end

      it do
        expect(Fs.tail_lines(path, limit_in_bytes: 1024)).to be_present
      end
    end
  end
end
