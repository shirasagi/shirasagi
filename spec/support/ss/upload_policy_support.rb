def upload_policy_before_settings(value = nil)
  SS.config.replace_value_at(:ss, :upload_policy, value)
  Fs.mkdir_p(SS.config.ss.sanitizer_input)
  Fs.mkdir_p(SS.config.ss.sanitizer_output)
end

def upload_policy_after_settings
  SS.config.replace_value_at(:ss, :upload_policy, nil)
  Fs.rm_rf(SS.config.ss.sanitizer_input)
  Fs.rm_rf(SS.config.ss.sanitizer_output)
end

def mock_sanitizer_restore(file, output_path = nil)
  unless output_path
    Fs.rm_rf file.path
    output_path = file.sanitizer_input_path.sub(/\A(.*)\./, '\\1_100_marked.')
    Fs.mv file.sanitizer_input_path, output_path
  end

  if job_model = Uploader::JobFile.sanitizer_restore(output_path)
    return job_model
  end

  if file = SS::UploadPolicy.sanitizer_restore(output_path)
    return file
  end

  return nil
end
