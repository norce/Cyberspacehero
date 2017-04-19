require 'ipaddr'

class Event < ActiveRecord::Base

  self.table_name = 'acid_event'

  def created_at
  #   Time.at self.packet_second
    self.timestamp
  end

  def src_ip
    number2ip self.ip_src
  end

  def dst_ip
    number2ip self.ip_dst
  end

  private

  def number2ip(number)
    IPAddr.new(number.abs, Socket::AF_INET).to_s unless number.nil?
  end

  def ip2number(ip)
    IPAddr.new(ip).to_i unless ip.nil? or ip.empty?
  end
end
