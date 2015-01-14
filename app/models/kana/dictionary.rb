class Kana::Dictionary
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::Permission

  # field separator
  FS = %w[, 、 ，]

  # default cost
  DEFAULT_COST = 10

  # default part-of-speech
  DEFAULT_POS = %w[名詞 固有名詞 一般 *]

  seqid :id
  field :name, type: String
  field :body, type: String

  permit_params :name, :body

  validates :name, presence: true
  validates :body, presence: true
  validate :validate_body

  public
    def validate_body
      each_csv
      errors.size == 0 ? true : false
    end

    def each_csv
      return if body.blank?

      idx = 0
      body.each_line do |line|
        idx = idx + 1
        line = line.to_s.gsub(/#.*/, "")
        line.strip!
        if line.blank?
          next
        end

        terms = line.split(/\s*(#{FS.join("|")})\s*/)
        unless terms[0] && terms[1]
          errors.add :base, :malformed_kana_dictionary, line: line, no: idx
          next
        end

        word = terms[0].strip
        yomi = terms[2].strip.tr("ぁ-ん", "ァ-ン")

        if yomi !~ /^[ァ-ンーヴ]+$/
          errors.add :base, :malformed_kana_dictionary, line: line, no: idx
          next
        end

        yield word, yomi if block_given?
      end
    end

    class << self
      public
        def master_root
          "#{Rails.root}/private/files/kana_dictionaries"
        end

        def master_dic(site_id)
          self.master_root + "/" + site_id.to_s.split(//).join("/") + "/_/user.dic"
        end

        def build_dic(site_id)
          mecab_indexer = SS.config.kana.mecab_indexer
          mecab_dicdir = SS.config.kana.mecab_dicdir

          raise I18n.t("kana.build_fail.no_mecab_indexer") unless ::File.exists?(mecab_indexer)
          raise I18n.t("kana.build_fail.no_mecab_dicdir") unless ::Dir.exists?(mecab_dicdir)

          ::Dir.mktmpdir do |dir|
            tmp_src = ::Tempfile::new(["mecab", ".csv"], dir)

            count = 0
            ::File.open(tmp_src, "w:UTF-8") do |f|
              self.where(site_id: site_id).each do |item|
                item.each_csv do |word, yomi|
                  f.puts "#{word},*,*,#{DEFAULT_COST},#{DEFAULT_POS[0]},#{DEFAULT_POS[1]},#{DEFAULT_POS[2]},#{DEFAULT_POS[3]},*,*,#{word},#{yomi},#{yomi}"
                  count = count + 1
                end

                if item.errors.size > 0
                  logger.warn("dictionary #{item.name} has #{errors.size} error(s).")
                end
              end
            end

            if count == 0
              raise I18n.t("kana.build_fail.no_content")
            end

            tmp_dic = Tempfile::new(["mecab", ".dic"], dir)
            cmd = "#{mecab_indexer} -d #{mecab_dicdir} -u #{tmp_dic.path} -f UTF-8 -t UTF-8 #{tmp_src.path}"
            logger.info("system(#{cmd})")
            system(cmd)
            raise I18n.t("kana.build_fail.index") if $?.exitstatus != 0

            # upload user.dic
            master_file = master_dic(site_id)
            Fs.binwrite(master_file, ::IO.binread(tmp_dic.path))
          end
        end

        def pull(site_id)
          master_file = master_dic(site_id)
          unless Fs.exists?(master_file)
            yield nil
            return
          end

          Dir.mktmpdir do |dir|
            local_file = ::File.join(dir, "user.dic")
            ::IO.binwrite(local_file, Fs.binread(master_file))

            yield local_file
          end
        end
    end
end
