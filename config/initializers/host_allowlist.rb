# Allow additional hostnames from the HOSTS environment variable.
# Comma-separated. Example: HOSTS="copy1.test,copy2.test"
ENV['HOSTS'].to_s.split(',').map(&:strip).reject(&:empty?).each do |host|
  Rails.application.config.hosts << host
end
