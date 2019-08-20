class Article::Agents::Tasks::Page::PagesController < ApplicationController
  def import
    importer = Article::Page::Importer.new(@site, @node, @user)
    importer.import(@file, task: @task)
    @file.destroy
    head :ok
  end
end
