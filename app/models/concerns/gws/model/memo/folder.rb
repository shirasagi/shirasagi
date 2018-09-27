module Gws::Model::Memo::Folder
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Schedule::Colorize
  include SS::Fields::DependantNaming

  module ClassMethods
    def tree_sort(options = {})
      SS::TreeList.build self, options
    end
  end

  def trailing_name
    @trailing_name ||= name.split("/")[depth..-1].join("/")
  end

  def depth
    @depth ||= begin
      count = 0
      full_name = ""
      name.split("/").map do |part|
        full_name << "/" if full_name.present?
        full_name << part

        break if name == full_name

        found = self.class.where(name: full_name).first
        break if found.blank?

        count += 1
      end
      count
    end
  end
end
