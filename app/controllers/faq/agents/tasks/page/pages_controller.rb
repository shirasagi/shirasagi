class Faq::Agents::Tasks::Page::PagesController < ApplicationController
  def import
    importer = Faq::Page::Importer.new(@site, @node, @user)
    importer.import(@file, task: @task)
    @file.destroy
    head :ok
  end
end
