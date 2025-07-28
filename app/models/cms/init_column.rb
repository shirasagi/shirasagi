class Cms::InitColumn
  include SS::Document
  include SS::Model::InitColumn
  include SS::Reference::Site

  store_in collection: 'cms_init_columns'

  def path
    self.column_type.underscore.sub('/column/', '/agents/columns/')
  end

  def column_form_partial_path
    "#{path}/column_form" if File.exist?("#{Rails.root}/app/views/#{path}/_column_form.html.erb")
  end
end
