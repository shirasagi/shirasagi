if @model.tinymce?
  json.partial! 'tinymce_template'
end
