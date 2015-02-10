module Ezine::Config
  cattr_reader(:default_values) do
    {
      deliver_verification_mail_from_here: true,
      register_member_here: true,
      sleep_seconds: 0,
      interval: 1,
    }
  end
end
