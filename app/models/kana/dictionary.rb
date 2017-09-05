class Kana::Dictionary
  extend SS::Translation
  include SS::Document
  include SS::Reference::Site
  include Cms::SitePermission

  # field separator
  FS = %w(, 、 ，).freeze

  # default cost
  DEFAULT_COST = 10

  # default part-of-speech
  DEFAULT_POS = %w(名詞 固有名詞 一般 *).freeze

  DEFAULT_MASTER_ROOT = Rails.root.join("private", "files", "kana_dictionaries").to_s.freeze

  seqid :id
  field :name, type: String
  field :body, type: String

  permit_params :name, :body

  #text_index :name, :body

  validates :name, presence: true
  validates :body, presence: true
  validate :validate_body

  def validate_body
    enumerate_csv.count
    errors.blank?
  end

  def enumerate_csv
    Kana::CsvEnumerable.new self
  end

  class << self
    def master_root
      SS.config.kana.root || DEFAULT_MASTER_ROOT
    end

    def master_dic(site_id)
      self.master_root + "/" + site_id.to_s.split(//).join("/") + "/_/user.dic"
    end

    def build_dic(site_id, item_ids)
      mecab_indexer = SS.config.kana.mecab_indexer
      mecab_dicdir = SS.config.kana.mecab_dicdir

      raise I18n.t("kana.build_fail.no_mecab_indexer") unless ::File.exists?(mecab_indexer)
      raise I18n.t("kana.build_fail.no_mecab_dicdir") unless ::Dir.exists?(mecab_dicdir)

      ::Dir.mktmpdir do |dir|
        tmp_src = File.join(dir, make_tmpname("txt"))

        count = build_source(build_criteria(site_id, item_ids), tmp_src)
        return I18n.t("kana.build_fail.no_content") if count == 0

        tmp_dic = File.join(dir, make_tmpname("dic"))
        run_mecab_indexer(tmp_src, tmp_dic)

        # upload user.dic
        master_file = master_dic(site_id)
        Fs.binwrite(master_file, ::IO.binread(tmp_dic))
      end
      nil
    end

    def pull(site_id)
      master_file = master_dic(site_id)
      unless Fs.exists?(master_file)
        return yield nil
      end

      Dir.mktmpdir do |dir|
        local_file = ::File.join(dir, "user.dic")
        ::IO.binwrite(local_file, Fs.binread(master_file))
        master_stat = Fs.stat(master_file)
        File.utime(master_stat.atime, master_stat.mtime, local_file)
        return yield local_file
      end
    end

    def search(params)
      criteria = self.where({})
      return criteria if params.blank?

      if params[:name].present?
        criteria = criteria.search_text params[:name]
      end
      if params[:keyword].present?
        criteria = criteria.keyword_in params[:keyword], :name, :body
      end
      criteria
    end

    private

    def build_criteria(site_id, item_ids)
      criteria = where(site_id: site_id)
      criteria = criteria.where(:id.in => item_ids) if item_ids.present?
      criteria
    end

    def make_tmpname(suffix)
      # blow code come from Tmpname::make_tmpname
      "mecab#{Time.zone.now.strftime("%Y%m%d")}-#{$PID}-#{rand(0x100000000).to_s(36)}#{suffix}"
    end

    def build_source(criteria, output_file)
      count = 0
      ::File.open(output_file, "w:UTF-8") do |f|
        each_all_csv(criteria) do |word, yomi|
          f.puts "#{word},*,*,#{DEFAULT_COST},#{DEFAULT_POS.join(',')},*,*,#{word},#{yomi},#{yomi}"
          count += 1
        end
      end
      count
    end

    def each_all_csv(criteria)
      criteria.each do |item|
        item.enumerate_csv.each do |word, yomi|
          yield word, yomi
        end
        logger.warn("dictionary #{item.name} has #{item.errors.size} error(s).") if item.errors.present?
      end
    end

    def run_mecab_indexer(input_file, output_file)
      mecab_indexer = SS.config.kana.mecab_indexer
      mecab_dicdir = SS.config.kana.mecab_dicdir

      cmd = "#{mecab_indexer} -d #{mecab_dicdir} -u #{output_file} -f UTF-8 -t UTF-8 #{input_file}"
      logger.info("system(#{cmd})")
      system(cmd)
      raise I18n.t("kana.build_fail.index") if $CHILD_STATUS.exitstatus != 0
    end
  end
end
