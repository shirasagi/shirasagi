module Gws::Model::Memo::Folder
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include Gws::Referenceable
  include Gws::Schedule::Colorize
  include SS::Fields::DependantNaming

  attr_accessor :in_parent, :in_basename

  module ClassMethods
    def tree_sort(options = {})
      SS::TreeList.build self, options
    end
  end

  def trailing_name
    # @trailing_name ||= name.split("/")[depth..-1].join("/")
    @trailing_name ||= name.split("/")[depth..-1].join("/") if name.present?
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

  def parent
    @parent ||= begin
      if name.present?
        parent_name = ::File.dirname(name)
        dependant_scope.where(name: parent_name).first
      end
    end
  end

  def set_name_and_depth
    if in_parent.present?
      parent_folder = dependant_scope.find(in_parent) rescue nil
    end

    if parent_folder.present?
      self.name = "#{parent_folder.name}/#{in_basename}"
    else
      self.name = in_basename
    end
  end
end
