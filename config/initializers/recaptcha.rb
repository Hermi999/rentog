Recaptcha.configure do |config|
  config.public_key  = APP_CONFIG.recaptcha_public_key
  config.private_key = APP_CONFIG.recaptcha_private_key
  #config.api_version = 'v2'
end
