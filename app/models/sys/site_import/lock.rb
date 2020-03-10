class Sys::SiteImport::Lock

  module Sys::SiteImport::Lock::DestroyUnable
    extend ActiveSupport::Concern

    included do
      before_destroy :invalid_destroy_with_sys_site_import
    end

    def under_sequence_value?
      lock = Sys::SiteImport::LockSequence.find_by(ref_collection_name: self.class.collection.name)
      id <= lock.value
    end

    def invalid_destroy_with_sys_site_import
      if under_sequence_value?
        raise "invalid destroy occurred! : #{self.class} #{self.id}"
      end
    rescue => e
      STDERR.puts "#{e}\n#{e.backtrace.join("\n  ")}"
      exit!
    end
  end

  class << self
    def init_lock_sequence
      SS::Sequence.each do |item|
        lock = Sys::SiteImport::LockSequence.find_or_initialize_by(ref_collection_name: item.id)
        lock.value = item.value
        lock.save!
      end
    end

    def init_destroy_unable
      # groups
      SS::Group.include Sys::SiteImport::Lock::DestroyUnable
      Cms::Group.include Sys::SiteImport::Lock::DestroyUnable
      Gws::Group.include Sys::SiteImport::Lock::DestroyUnable
      Sys::Group.include Sys::SiteImport::Lock::DestroyUnable
      Webmail::Group.include Sys::SiteImport::Lock::DestroyUnable

      # user
      SS::User.include Sys::SiteImport::Lock::DestroyUnable
      Cms::User.include Sys::SiteImport::Lock::DestroyUnable
      Gws::User.include Sys::SiteImport::Lock::DestroyUnable
      Webmail::User.include Sys::SiteImport::Lock::DestroyUnable

      # roles
      Sys::Role.include Sys::SiteImport::Lock::DestroyUnable
      Cms::Role.include Sys::SiteImport::Lock::DestroyUnable
      Gws::Role.include Sys::SiteImport::Lock::DestroyUnable
      Webmail::Role.include Sys::SiteImport::Lock::DestroyUnable

      # files
      SS::File.include Sys::SiteImport::Lock::DestroyUnable
      SS::TempFile.include Sys::SiteImport::Lock::DestroyUnable
      SS::UserFile.include Sys::SiteImport::Lock::DestroyUnable
      SS::LinkFile.include Sys::SiteImport::Lock::DestroyUnable
      SS::StreamingFile.include Sys::SiteImport::Lock::DestroyUnable
      Cms::File.include Sys::SiteImport::Lock::DestroyUnable
      Cms::TempFile.include Sys::SiteImport::Lock::DestroyUnable
      Member::File.include Sys::SiteImport::Lock::DestroyUnable
      Member::PhotoFile.include Sys::SiteImport::Lock::DestroyUnable
      Member::TempFile.include Sys::SiteImport::Lock::DestroyUnable
      Rss::TempFile.include Sys::SiteImport::Lock::DestroyUnable
      Facility::TempFile.include Sys::SiteImport::Lock::DestroyUnable
      Webmail::History::ArchiveFile.include Sys::SiteImport::Lock::DestroyUnable

      # cms_forms
      Cms::Form.include Sys::SiteImport::Lock::DestroyUnable

      # cms_loop_settings
      Cms::LoopSetting.include Sys::SiteImport::Lock::DestroyUnable

      # cms_layouts
      Cms::Layout.include Sys::SiteImport::Lock::DestroyUnable

      # cms_nodes
      Cms::Node.include Sys::SiteImport::Lock::DestroyUnable

      # cms_parts
      Cms::Part.include Sys::SiteImport::Lock::DestroyUnable

      # cms_pages
      Cms::Page.include Sys::SiteImport::Lock::DestroyUnable
      Article::Page.include Sys::SiteImport::Lock::DestroyUnable

      # opendata_dataset_groups
      Opendata::DatasetGroup.include Sys::SiteImport::Lock::DestroyUnable

      # opendata_licenses
      Opendata::License.include Sys::SiteImport::Lock::DestroyUnable
    end
  end
end
