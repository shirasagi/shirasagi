require 'rss'

class Rss::ImportFromFileJob < Rss::ImportBase
  private
    def before_import(file, *args)
      super

      @cur_file = Rss::TempFile.where(site_id: site.id, id: file).first
      return unless @cur_file

      @items = Rss::Wrappers.parse(@cur_file)
    end

    def after_import
      super

      gc_rss_tempfile
    end

    def gc_rss_tempfile
      return if rand(100) >= 20
      Rss::TempFile.lt(updated: 2.weeks.ago).destroy_all
    end
end
