module Cms::FileRepair
  class Repairer
    UTF8_BOM = "\uFEFF".freeze

    attr_reader :site, :csv, :csv_path, :timestamp

    def initialize
      @timestamp = Time.zone.now.strftime("%Y%m%d_%H%M_%3N")
    end

    private

    def set_site(site)
      @site = site
    end

    def set_csv_path(action)
      path = ::File.join(self.class.output_path, "#{action}_#{timestamp}")
      @csv_path = ::File.join(path, "#{site.name}.csv")
    end

    def csv_open
      Fs.rm_rf(csv_path) if ::File.exist?(csv_path)
      Fs.mkdir_p(::File.dirname(csv_path))
      file = ::File.open(csv_path, "w")
      file.print UTF8_BOM
      file.close
      @csv = CSV.open(csv_path, "a")
    end

    def each_body
      ids = Cms::Page.site(site).pluck(:id)
      ids.each_with_index do |id, idx|
        item = Cms::Page.find(id) rescue nil
        next unless item
        item = item.becomes_with_route
        puts "#{site.name} #{idx + 1}/#{ids.size}: #{item.name}"

        if item.respond_to?(:form) && item.form
          values = item.column_values
          values = values.to_a.select { |v| v._type == "Cms::Column::Value::Free" }
          values.each do |value|
            yield(item, value)
          end
        elsif item.respond_to?(:html)
          yield(item, item)
        end
      end
    end

    public

    def check_states(site)
      set_site(site)
      set_csv_path("check_states")
      csv_open
      csv.puts Cms::FileRepair::Issuer::FileState.header
      each_body do |item, body|
        issuer = Cms::FileRepair::Issuer::FileState.new(site, item, body)
        issuer.check_states
        issuer.issues_csv.each { |issue| csv << issue }
      end
      csv.close
      puts "output: #{csv_path}"
    end

    def fix_states(site)
      set_site(site)
      set_csv_path("fix_states")
      csv_open
      csv.puts Cms::FileRepair::Issuer::FileState.header
      each_body do |item, body|
        issuer = Cms::FileRepair::Issuer::FileState.new(site, item, body)
        issuer.fix_states
        issuer.fixes_csv.each { |fix| csv << fix }
      end
      csv.close
      puts "output: #{csv_path}"
    end

    def check_duplicates(site)
      set_site(site)
      set_csv_path("check_duplicates")
      csv_open
      csv.puts Cms::FileRepair::Issuer::Duplicate.header
      each_body do |item, body|
        issuer = Cms::FileRepair::Issuer::Duplicate.new(site, item, body)
        issuer.check_duplicates
        issuer.issues_csv.each { |issue| csv << issue }
      end
      csv.close
      puts "output: #{csv_path}"
    end

    def delete_duplicates(site)
      set_site(site)
      set_csv_path("delete_duplicates")
      csv_open
      csv.puts Cms::FileRepair::Issuer::Duplicate.header
      each_body do |item, body|
        issuer = Cms::FileRepair::Issuer::Duplicate.new(site, item, body)
        issuer.delete_duplicates
        issuer.fixes_csv.each { |fix| csv << fix }
      end
      csv.close
      puts "output: #{csv_path}"
    end

    class << self
      def output_path
        ::File.join(Rails.root.to_s, "private/file_repair")
      end

      def clean
        if ::File.exist?(output_path)
          puts "remove: #{output_path}"
          Fs.rm_rf(output_path)
        end
      end
    end
  end
end
