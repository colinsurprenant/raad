Logger.info("info from config in env=#{Raad::env}")

configuration do
  set :daemon_name, 'dummy'
  set :log_level, :error
end
