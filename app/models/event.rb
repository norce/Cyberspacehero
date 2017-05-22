require 'ipaddr'

class Event < ActiveRecord::Base

  self.table_name = 'acid_event'

  LEVELS = %w[high medium low]
  SIG_LEVEL_IDS = {high: [], medium: [], low: []}
  SIG_CLASS_TYPES.each do |sig_class|
    sig_level = LEVELS[sig_class[:priority] - 1]
    SIG_LEVEL_IDS[sig_level.to_sym] << sig_class[:id]
  end

  def created_at
    # Time.at self.packet_second
    self.timestamp
  end

  def src_ip
    number2ip self.ip_src
  end

  def dst_ip
    number2ip self.ip_dst
  end

  def sig_type
    SIG_CLASS_TYPES[self.sig_class_id][:type]
  end

  private

  def number2ip(number)
    IPAddr.new(number.abs, Socket::AF_INET).to_s unless number.nil?
  end

  def ip2number(ip)
    IPAddr.new(ip).to_i unless ip.nil? or ip.empty?
  end
end
