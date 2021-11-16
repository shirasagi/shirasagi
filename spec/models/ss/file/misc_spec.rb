require 'spec_helper'

describe SS::File, dbscope: :example do
  context "with empty" do
    subject { described_class.new }

    it do
      expect(subject).to be_invalid
      expect(subject.errors.count).to eq 4
      expect(subject.errors[:model]).to include I18n.t("errors.messages.blank")
      expect(subject.errors[:name]).to include I18n.t("errors.messages.blank")
      expect(subject.errors[:filename]).to include I18n.t("errors.messages.blank")
      expect(subject.errors[:content_type]).to include I18n.t("errors.messages.blank")
    end
  end

  context "create file with empty contents" do
    let(:filename) { "#{unique_id}.png" }
    let(:basename) { ::File.basename(filename, ".*") }
    subject! { described_class.create(model: described_class.name.underscore, filename: filename) }

    it do
      expect(subject).to be_valid
      expect(subject.site_id).to be_blank
      expect(subject.user_id).to be_blank
      expect(subject.model).to eq described_class.name.underscore
      expect(subject.state).to eq "closed"
      expect(subject.name).to eq filename
      expect(subject.filename).to eq filename
      expect(subject.size).to eq 0
      expect(subject.content_type).to eq "image/png"
      expect(subject.owner_item_type).to be_blank
      expect(subject.owner_item_id).to be_blank
      expect(subject.geo_location).to be_blank
      expect(subject.csv_headers).to be_blank
      expect(subject.sanitizer_state).to be_blank
      expect(subject.path).to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}"
      expect(Fs.exist?(subject.path)).to be_falsey
      expect(subject.url).to eq "/fs/#{subject.id}/_/#{subject.filename}"
      expect(subject.thumb).to be_present
      expect(subject.thumb_url).to eq "/fs/#{subject.id}/_/#{basename}_normal.png"
    end
  end

  context "with 'filename' as SS.config.ss.file_url_with" do
    let(:base_of_name) { ss_japanese_text }
    let(:name) { "#{base_of_name}.png" }
    subject { create :ss_file, name: name }

    before do
      @save_file_url_with = SS.config.ss.file_url_with
      SS.config.replace_value_at(:ss, :file_url_with, "filename")
    end

    after do
      SS.config.replace_value_at(:ss, :file_url_with, @save_file_url_with)
    end

    its(:valid?) { is_expected.to be_truthy }
    its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
    its(:url) { is_expected.to eq "/fs/#{subject.id}/_/#{subject.filename}" }
    let(:thumb_basename) { "#{::File.basename(subject.filename, ".*")}_normal.#{subject.extname}" }
    its(:thumb_url) { is_expected.to eq "/fs/#{subject.id}/_/#{thumb_basename}" }
    its(:public?) { is_expected.to be_falsey }
    its(:public_dir) { is_expected.to be_nil }
    its(:public_path) { is_expected.to be_nil }
    its(:full_url) { is_expected.to be_nil }
    its(:name) { is_expected.to eq name }
    its(:humanized_name) { is_expected.to eq "#{base_of_name} (PNG 11.5KB)" }
    its(:download_filename) { is_expected.to eq "#{base_of_name}.png" }
    its(:basename) { is_expected.to eq 'logo.png' }
    its(:extname) { is_expected.to eq 'png' }
    its(:image?) { is_expected.to be_truthy }
  end

  context "with 'name' as SS.config.ss.file_url_with" do
    let(:base_of_name) { ss_japanese_text }
    let(:name) { "#{base_of_name}.png" }
    subject { create :ss_file, name: name }

    before do
      @save_file_url_with = SS.config.ss.file_url_with
      SS.config.replace_value_at(:ss, :file_url_with, "name")
    end

    after do
      SS.config.replace_value_at(:ss, :file_url_with, @save_file_url_with)
    end

    its(:valid?) { is_expected.to be_truthy }
    its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
    its(:url) { is_expected.to eq "/fs/#{subject.id}/_/#{CGI.escape(subject.name)}" }
    let(:thumb_basename) { "#{::File.basename(subject.name, ".*")}_normal.#{subject.extname}" }
    its(:thumb_url) { is_expected.to eq "/fs/#{subject.id}/_/#{CGI.escape(thumb_basename)}" }
    its(:public?) { is_expected.to be_falsey }
    its(:public_dir) { is_expected.to be_nil }
    its(:public_path) { is_expected.to be_nil }
    its(:full_url) { is_expected.to be_nil }
    its(:name) { is_expected.to eq name }
    its(:humanized_name) { is_expected.to eq "#{base_of_name} (PNG 11.5KB)" }
    its(:download_filename) { is_expected.to eq "#{base_of_name}.png" }
    its(:basename) { is_expected.to eq 'logo.png' }
    its(:extname) { is_expected.to eq 'png' }
    its(:image?) { is_expected.to be_truthy }
  end

  context "with item related to site" do
    let(:site) { ss_site }
    let(:base_of_name) { ss_japanese_text }
    let(:name) { "#{base_of_name}.png" }
    subject { create :ss_file, site_id: site.id, name: name }

    before do
      @save_file_url_with = SS.config.ss.file_url_with
      SS.config.replace_value_at(:ss, :file_url_with, "name")
    end

    after do
      SS.config.replace_value_at(:ss, :file_url_with, @save_file_url_with)
    end

    its(:valid?) { is_expected.to be_truthy }
    its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
    its(:url) { is_expected.to eq "/fs/#{subject.id}/_/#{CGI.escape(subject.name)}" }
    let(:thumb_basename) { "#{::File.basename(subject.name, ".*")}_normal.#{subject.extname}" }
    its(:thumb_url) { is_expected.to eq "/fs/#{subject.id}/_/#{CGI.escape(thumb_basename)}" }
    its(:public?) { is_expected.to be_falsey }
    its(:public_dir) { is_expected.to eq "#{site.root_path}/fs/#{subject.id}/_" }
    its(:public_path) { is_expected.to eq "#{site.root_path}/fs/#{subject.id}/_/#{subject.filename}" }
    its(:full_url) { is_expected.to eq "http://#{site.domain}/fs/#{subject.id}/_/#{CGI.escape(subject.name)}" }
    its(:name) { is_expected.to eq name }
    its(:humanized_name) { is_expected.to eq "#{base_of_name} (PNG 11.5KB)" }
    its(:download_filename) { is_expected.to eq name }
    its(:basename) { is_expected.to eq 'logo.png' }
    its(:extname) { is_expected.to eq 'png' }
    its(:image?) { is_expected.to be_truthy }
  end

  context "with item related to sub-dir site" do
    let(:site0) { ss_site }
    let(:site1) { create(:ss_site_subdir, domains: site0.domains, parent_id: site0.id) }
    let(:base_of_name) { ss_japanese_text }
    let(:name) { "#{base_of_name}.png" }
    subject { create :ss_file, site_id: site1.id, name: name }

    before do
      @save_file_url_with = SS.config.ss.file_url_with
      SS.config.replace_value_at(:ss, :file_url_with, "name")
    end

    after do
      SS.config.replace_value_at(:ss, :file_url_with, @save_file_url_with)
    end

    its(:valid?) { is_expected.to be_truthy }
    its(:path) { is_expected.to eq "#{SS::File.root}/ss_files/#{subject.id}/_/#{subject.id}" }
    its(:url) { is_expected.to eq "/fs/#{subject.id}/_/#{CGI.escape(subject.name)}" }
    let(:thumb_basename) { "#{::File.basename(subject.name, ".*")}_normal.#{subject.extname}" }
    its(:thumb_url) { is_expected.to eq "/fs/#{subject.id}/_/#{CGI.escape(thumb_basename)}" }
    its(:public?) { is_expected.to be_falsey }
    its(:public_dir) { is_expected.to eq "#{site0.root_path}/fs/#{subject.id}/_" }
    its(:public_path) { is_expected.to eq "#{site0.root_path}/fs/#{subject.id}/_/#{subject.filename}" }
    its(:full_url) { is_expected.to eq "http://#{site0.domain}/fs/#{subject.id}/_/#{CGI.escape(subject.name)}" }
    its(:name) { is_expected.to eq name }
    its(:humanized_name) { is_expected.to eq "#{base_of_name} (PNG 11.5KB)" }
    its(:download_filename) { is_expected.to eq name }
    its(:basename) { is_expected.to eq 'logo.png' }
    its(:extname) { is_expected.to eq 'png' }
    its(:image?) { is_expected.to be_truthy }
  end

  describe "#uploaded_file" do
    let(:file) { create :ss_file }
    subject { file.uploaded_file }
    its(:original_filename) { is_expected.to eq file.basename }
    its(:content_type) { is_expected.to eq file.content_type }
    # its(:tempfile) { is_expected.not_to be_nil }
    # its(:headers) { is_expected.not_to be_nil }
    its(:path) { is_expected.not_to be_nil }
    its(:size) { is_expected.to eq file.size }
    its(:eof?) { is_expected.to be_falsey }
    its(:read) { expect(subject.respond_to?(:read)).to be_truthy }
    its(:open) { expect(subject.respond_to?(:open)).to be_truthy }
    its(:close) { expect(subject.respond_to?(:close)).to be_truthy }
    its(:rewind) { expect(subject.respond_to?(:rewind)).to be_truthy }
  end

  describe "shirasagi-434" do
    before do
      @tmpdir = ::Dir.mktmpdir
      @file_path = "#{@tmpdir}/#{filename}"
      File.open(@file_path, "wb") do |file|
        file.write [1]
      end
    end

    after do
      ::FileUtils.rm_rf(@tmpdir)
    end

    before do
      # we need custom setting for jtd
      @save_config = SS.config.env.mime_type_map
      SS.config.replace_value_at(:env, :mime_type_map, mime_type_map)
    end

    after do
      SS.config.replace_value_at(:env, :mime_type_map, @save_config)
    end

    subject do
      file = SS::File.new model: "article/page"
      Fs::UploadedFile.create_from_file(@file_path, basename: "spec", content_type: "application/octet-stream") do |f|
        file.in_file = f
        file.save!
        file.in_file = nil
      end
      file.reload
      file
    end

    context "when pdf file is uploaded with application/octet-stream" do
      let(:filename) { "a.pdf" }
      let(:mime_type_map) { {} }
      its(:content_type) { is_expected.to eq "application/pdf" }
    end

    context "when js file is uploaded with application/octet-stream" do
      let(:filename) { "a.js" }
      let(:mime_type_map) { {} }
      its(:content_type) { is_expected.to eq "application/javascript" }
    end

    context "when jtd file is uploaded with application/octet-stream" do
      let(:filename) { "a.jtd" }
      let(:mime_type_map) { { "jtd" => "application/x-js-taro" } }
      its(:content_type) { is_expected.to eq "application/x-js-taro" }
    end

    context "when wmv file is uploaded with application/octet-stream" do
      let(:filename) { "a.wmv" }
      let(:mime_type_map) { { "wmv" => "video/x-ms-wmv" } }
      its(:content_type) { is_expected.to eq "video/x-ms-wmv" }
    end
  end

  describe "#validate_size" do
    let(:test_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
    let(:test_file) { Fs::UploadedFile.create_from_file(test_file_path, basename: "spec") }

    after do
      test_file.close unless test_file.closed?
    end

    subject do
      file = SS::File.new model: "article/page"
      file.in_file = test_file
      file
    end

    context "when max_filesize is limited" do
      before do
        @save_config = SS.config.env.max_filesize
        SS.config.replace_value_at(:env, :max_filesize, 50)
      end

      after do
        SS.config.replace_value_at(:env, :max_filesize, @save_config)
      end

      it do
        expect(subject.save).to be_falsey
        expect(subject.errors[:base]).not_to be_empty
        expect(subject.errors[:base].first).to include("logo.png", "サイズが大きすぎます", "制限値: 50バイト")
      end
    end

    context "when max_filesize_ext is limited" do
      before do
        @save_config = SS.config.env.max_filesize_ext
        SS.config.replace_value_at(:env, :max_filesize_ext, { "png" => 23 })
      end

      after do
        SS.config.replace_value_at(:env, :max_filesize_ext, @save_config)
      end

      it do
        expect(subject.save).to be_falsey
        expect(subject.errors[:base]).not_to be_empty
        expect(subject.errors[:base].first).to include("logo.png", "サイズが大きすぎます", "制限値: 23バイト")
      end
    end
  end

  describe "shirasagi-1066" do
    let(:multi_frame_image) { "#{::Rails.root}/spec/fixtures/ss/file/keyvisual.gif" }

    context "when save multi frame image" do
      subject do
        file = SS::File.new model: "article/page"
        Fs::UploadedFile.create_from_file(multi_frame_image) do |f|
          file.in_file = f
          file.save!
          file.in_file = nil
        end
        file.reload
        file
      end

      it "#save_file" do
        image = MiniMagick::Image.open(subject.path)
        expect(image.frames.size).to eq 5
        image.destroy!
      end
    end

    context "when save multi frame image with resizing" do
      subject do
        file = SS::File.new model: "article/page"
        Fs::UploadedFile.create_from_file(multi_frame_image) do |f|
          file.in_file = f
          file.resizing = [320, 240]
          file.save!
          file.in_file = nil
        end
        file.reload
        file
      end

      it "#save_file" do
        image = MiniMagick::Image.open(subject.path)
        expect(image.frames.size).to eq 5
        image.destroy!
      end
    end
  end

  describe "#copy" do
    context "when non-image file is given" do
      let(:src) do
        file = SS::File.new
        Fs::UploadedFile.create_from_file("spec/fixtures/cms/all_contents_1.csv") do |upload_file|
          file.in_file = upload_file
          file.model = "ss/file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy }

      it do
        # expect(src.thumb).to be_blank

        expect(copy.id).not_to eq src.id
        expect(copy.name).to eq src.name
        expect(copy.filename).to eq src.filename
        expect(copy.content_type).to eq src.content_type
        expect(copy.size).to eq src.size
        expect(copy.model).to eq "ss/temp_file"
        expect(copy.thumb).to be_present
      end
    end

    context "when non-image file is given" do
      let(:src) do
        file = SS::File.new
        Fs::UploadedFile.create_from_file("spec/fixtures/ss/logo.png") do |upload_file|
          file.in_file = upload_file
          file.model = "ss/file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy }

      it do
        expect(src.thumb).not_to be_blank

        expect(copy.id).not_to eq src.id
        expect(copy.name).to eq src.name
        expect(copy.filename).to eq src.filename
        expect(copy.content_type).to eq src.content_type
        expect(copy.size).to eq src.size
        expect(copy.model).to eq "ss/temp_file"
        expect(copy.thumb.to_json).not_to eq src.thumb.to_json
      end
    end

    context "when a file copies from one user to other user and specific node" do
      let(:site) { create(:cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp") }
      let(:group) { create(:cms_group, name: unique_id) }
      let(:user1) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }
      let(:user2) { create(:cms_user, name: unique_id, email: "#{unique_id}@example.jp", group_ids: [ group.id ]) }
      let(:node) { create(:article_node_page, cur_site: site) }
      let(:src) do
        tmp_ss_file(
          Cms::File,
          site: site, user: user1, model: "cms/file", contents: "#{Rails.root}/spec/fixtures/ss/logo.png",
          group_ids: user1.group_ids
        )
      end

      it do
        copy = src.copy(cur_user: user2, cur_site: site, cur_node: node)

        expect(copy).to be_a(Cms::TempFile)
        expect(copy.id).not_to eq src.id
        expect(copy.name).to eq src.name
        expect(copy.filename).to eq src.filename
        expect(copy.content_type).to eq src.content_type
        expect(copy.size).to eq src.size
        expect(copy.model).to eq "ss/temp_file"
        expect(copy.user_id).to eq user2.id
        expect(copy.node_id).to eq node.id
      end
    end
  end

  describe "#copy_if_necessary" do
    context "when ss/file is given" do
      let(:src) do
        file = SS::File.new
        Fs::UploadedFile.create_from_file("spec/fixtures/cms/all_contents_1.csv") do |upload_file|
          file.in_file = upload_file
          file.model = "ss/file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy_if_necessary }

      it do
        expect(copy).to eq src
      end
    end

    context "when ss/user_file is given" do
      let(:src) do
        file = SS::UserFile.new
        Fs::UploadedFile.create_from_file("spec/fixtures/cms/all_contents_1.csv") do |upload_file|
          file.in_file = upload_file
          file.model = "ss/user_file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy_if_necessary }

      it do
        expect(copy).not_to eq src
      end
    end

    context "when cms/file is given" do
      let(:site) { create :cms_site }
      let(:src) do
        file = Cms::File.new
        Fs::UploadedFile.create_from_file("spec/fixtures/cms/all_contents_1.csv") do |upload_file|
          file.cur_site = site
          file.in_file = upload_file
          file.model = "cms/file"
          file.save!
        end
        file
      end
      let(:copy) { src.copy_if_necessary }

      it do
        expect(copy).not_to eq src
      end
    end
  end

  describe "what ss/file exports to liquid" do
    let(:assigns) { {} }
    let(:registers) { {} }
    subject { file.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    context "with image file" do
      let!(:file) { create :ss_file }

      it do
        expect(subject.name).to eq file.name
        expect(subject.extname).to eq file.extname
        expect(subject.size).to eq file.size
        expect(subject.humanized_name).to eq file.humanized_name
        expect(subject.filename).to eq file.filename
        expect(subject.basename).to eq file.basename
        expect(subject.url).to eq file.url
        expect(subject.thumb_url).to be_present
        expect(subject.thumb_url).to eq file.thumb_url
        expect(subject.image?).to be_truthy
      end
    end

    context "with pdf file" do
      let(:path) { Rails.root.join("spec/fixtures/ss/shirasagi.pdf") }
      let!(:file) do
        Fs::UploadedFile.create_from_file(path, content_type: 'application/pdf') do |file|
          create :ss_file, in_file: file
        end
      end

      it do
        expect(subject.name).to eq file.name
        expect(subject.extname).to eq file.extname
        expect(subject.size).to eq file.size
        expect(subject.humanized_name).to eq file.humanized_name
        expect(subject.filename).to eq file.filename
        expect(subject.basename).to eq file.basename
        expect(subject.url).to eq file.url
        expect(subject.thumb_url).to be_present
        expect(subject.image?).to be_falsey
      end
    end
  end

  describe "#download_filename" do
    context "when name is with ext" do
      subject { tmp_ss_file(contents: '0123456789', basename: "text.txt") }

      its(:download_filename) { is_expected.to eq "text.txt" }
    end

    context "when name is without ext" do
      subject { tmp_ss_file(contents: '0123456789', basename: "text") }

      its(:download_filename) { is_expected.to eq "text" }
    end

    context "when name ends with period" do
      subject { tmp_ss_file(contents: '0123456789', basename: "text.") }

      its(:download_filename) { is_expected.to eq "text" }
    end
  end

  describe "#image_dimension" do
    context "when image file is given" do
      let(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg") }

      it do
        expect(ss_file.image_dimension).to eq [ 712, 210 ]
      end
    end

    context "when non-image file is given" do
      let(:ss_file) { tmp_ss_file(contents: "0123", content_type: "application/octet-stream") }

      it do
        expect(ss_file.image_dimension).to be_nil
      end
    end

    context "when actual file is not existed (this is like that a file is isolated by anti-virus softwares)" do
      let(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg") }

      before do
        ::FileUtils.rm_f(ss_file.path)
      end

      it do
        expect(ss_file.image_dimension).to be_nil
      end
    end

    context "when actual file is replaced by directory" do
      let(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg") }

      before do
        ::FileUtils.rm_f(ss_file.path)
        ::FileUtils.mkdir_p(ss_file.path)
      end

      it do
        expect(ss_file.image_dimension).to be_nil
      end
    end
  end

  describe "#shrink_image_to" do
    let(:ss_file) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg") }

    before do
      expect(ss_file.image_dimension).to eq [ 712, 210 ]
    end

    context "shrink" do
      it do
        prev_size = ss_file.size
        expect(ss_file.shrink_image_to(100, 100)).to be_truthy

        ss_file.reload
        expect(ss_file.size).to be < prev_size
        expect(ss_file.image_dimension).to eq [ 100, 29 ]
      end
    end

    context "expand" do
      it do
        prev_size = ss_file.size
        expect(ss_file.shrink_image_to(1000, 1000)).to be_truthy

        ss_file.reload
        expect(ss_file.size).to eq prev_size
        expect(ss_file.image_dimension).to eq [ 712, 210 ]
      end
    end
  end

  describe "#url" do
    subject { create :ss_file }

    before do
      @save_file_url_with = SS.config.ss.file_url_with
      SS.config.replace_value_at(:ss, :file_url_with, "name")
    end

    after do
      SS.config.replace_value_at(:ss, :file_url_with, @save_file_url_with)
    end

    context "when '+' is given to name" do
      it do
        subject.name = "a+b.txt"
        # '+' is not escaped
        expect(subject.url).to eq "/fs/#{subject.id}/_/a+b.txt"
      end
    end

    context "when ' ' is given to name" do
      it do
        subject.name = "a b.txt"
        # ' ' is escaped with percent encoding
        expect(subject.url).to eq "/fs/#{subject.id}/_/a%20b.txt"
      end
    end

    context "when '@' is given to name" do
      it do
        subject.name = "a@b.txt"
        # '@' is not escaped
        expect(subject.url).to eq "/fs/#{subject.id}/_/a@b.txt"
      end
    end

    context "when rfc3986's unreserved symbol is given to name" do
      let(:rfc3986_unreserved_symbols) { %w(- . _ ~) }

      it do
        # unreserved symbols are not escaped
        subject.name = "a#{rfc3986_unreserved_symbols.join}b.txt"
        expect(subject.url).to eq "/fs/#{subject.id}/_/#{subject.name}"
      end
    end

    context "when rfc3986's sub-delims symbol is given to name" do
      let(:rfc3986_sub_delims) { %w(! $ & ' ( ) * + , ; =) }
      let(:filesystem_unsafe_on_windows) { %w(\\ / : * ? " < > |) }

      it do
        # sub delims are not escaped
        subject.name = "a#{(rfc3986_sub_delims - filesystem_unsafe_on_windows).join}b.txt"
        expect(subject.url).to eq "/fs/#{subject.id}/_/#{subject.name}"
      end
    end

    context "when unsafe chars is given to name" do
      it do
        subject.name = "a/b.txt"
        expect(subject.url).to eq "/fs/#{subject.id}/_/#{subject.filename}"
      end
    end
  end

  describe ".each_file" do
    let(:site) { cms_site }
    let(:user) { cms_user }
    let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
    let!(:file1) { tmp_ss_file(SS::TempFile, site: site, user: user, contents: file_path, basename: "logo1.png") }
    let!(:file2) do
      tmp_ss_file(SS::File, site: site, user: user, model: "ads/banner", contents: file_path, basename: "logo2.png")
    end
    let!(:file3) do
      tmp_ss_file(Board::File, site: site, user: user, model: "board/post", contents: file_path, basename: "logo3.png")
    end
    let!(:file4) do
      tmp_ss_file(Cms::File, site: site, user: user, model: "cms/file", contents: file_path, basename: "logo4.png")
    end
    let!(:file5) do
      tmp_ss_file(Member::PhotoFile, site: site, user: user, model: "member/photo", contents: file_path, basename: "logo5.png")
    end
    let!(:file6) do
      tmp_ss_file(Member::File, site: site, user: user, model: "member/blog_page", contents: file_path, basename: "logo6.png")
    end

    it do
      SS::File.each_file([ file1.id, file2.id, file3.id, file4.id, file5.id, file6.id ]) do |item|
        if item.id == file1.id
          expect(item.class).to eq file1.class
        elsif item.id == file2.id
          expect(item.class).to eq file2.class
        elsif item.id == file3.id
          expect(item.class).to eq file3.class
        elsif item.id == file4.id
          expect(item.class).to eq file4.class
        elsif item.id == file5.id
          expect(item.class).to eq file5.class
        elsif item.id == file6.id
          expect(item.class).to eq file6.class
        end
      end
    end
  end

  describe ".file_owned?" do
    context "with cms" do
      let!(:site) { cms_site }
      let!(:user) { cms_user }
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
      let!(:column1) do
        create(:cms_column_file_upload, cur_site: site, cur_form: form, order: 1, file_type: "image")
      end
      let!(:item) { create :article_page, cur_site: site, cur_user: user, form: form }
      let!(:file1) { tmp_ss_file(site: site, user: user, contents: "#{Rails.root}/spec/fixtures/ss/logo.png") }

      before do
        item.column_values = [
          column1.value_type.new(column: column1, file_id: file1.id, file_label: file1.humanized_name),
        ]
        item.save!

        file1.reload
      end

      it do
        expect(SS::File.file_owned?(file1, item)).to be_truthy
        expect(SS::File.file_owned?(file1, item.column_values.first)).to be_falsey
      end
    end
  end

  describe ".clone_file" do
    let(:site) { cms_site }
    let(:user) { cms_user }
    let(:file_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }

    context "with some file classes" do
      subject { SS::File.clone_file(file) }

      context "with SS::File" do
        let!(:file) do
          tmp_ss_file(SS::File, site: site, user: user, model: "ads/banner", contents: file_path)
        end

        it do
          expect(subject.class).to eq file.class
          expect(subject.name).to eq file.name
          expect(subject.filename).to eq file.filename
          expect(subject.size).to eq file.size
          expect(subject.content_type).to eq file.content_type
          expect(Fs.compare_file_head(subject.path, file.path)).to be_truthy
        end
      end

      context "with Member::PhotoFile" do
        let!(:file) do
          tmp_ss_file(Member::PhotoFile, site: site, user: user, model: "member/photo", contents: file_path)
        end

        it do
          expect(subject.class).to eq file.class
          expect(subject.name).to eq file.name
          expect(subject.filename).to eq file.filename
          expect(subject.size).to eq file.size
          expect(subject.content_type).to eq file.content_type
          expect(Fs.compare_file_head(subject.path, file.path)).to be_truthy
        end
      end
    end

    context "with some parameters" do
      let!(:file) { tmp_ss_file(site: site, user: user, contents: file_path) }
      let!(:owner_item) { create :cms_page, file_ids: [ file.id ] }

      before do
        file.reload
        expect(file.user_id).to eq user.id
        expect(file.owner_item_type).to eq owner_item.class.name
        expect(file.owner_item_id).to eq owner_item.id
      end

      context "with cur_user" do
        let!(:user1) { create :cms_user, name: unique_id, uid: unique_id, group_ids: user.group_ids }
        subject { SS::File.clone_file(file, cur_user: user1) }

        it do
          expect(subject.class).to eq file.class
          expect(subject.user_id).to eq user1.id
        end
      end

      context "without cur_user" do
        subject { SS::File.clone_file(file) }

        it do
          expect(subject.class).to eq file.class
          expect(subject.user_id).to be_blank
        end
      end

      context "with owner_item" do
        let!(:owner_item1) { create :article_page }
        subject { SS::File.clone_file(file, owner_item: owner_item1) }

        it do
          expect(subject.class).to eq file.class
          expect(subject.owner_item_type).to eq owner_item1.class.name
          expect(subject.owner_item_id).to eq owner_item1.id
        end
      end

      context "without owner_item" do
        subject { SS::File.clone_file(file) }

        it do
          expect(subject.class).to eq file.class
          expect(subject.owner_item_type).to be_blank
          expect(subject.owner_item_id).to be_blank
        end
      end
    end
  end
end
