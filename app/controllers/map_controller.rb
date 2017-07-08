class MapController < ApplicationController
  def index
    render layout: false
  end

  def world
    target_ip = '125.219.116.29'

    # src_ips = Event.select('DISTINCT ip_src').collect { |event| event.src_ip }
    # dst_ips = Event.select('DISTINCT ip_dst').collect { |event| event.dst_ip }
    # @ips = (src_ips + dst_ips).uniq

    src_events = Event.select('DISTINCT ip_src, COUNT(ip_src) AS count').group(:ip_src)
    dst_events = Event.select('DISTINCT ip_dst, COUNT(ip_dst) AS count').group(:ip_dst)
    # src_ips = src_events.collect { |event| event.src_ip }
    # dst_ips = dst_events.collect { |event| event.dst_ip }

    @areas = {} if @areas.nil?
    @located = {} if @located.nil?
    @dislocated = {} if @dislocated.nil?

    located_count = 0
    # @ips.each do |ip|
    #   location = IP_LOCATION_SEEKER.seek(ip)
    #
    #   [3, 2].each do |length|
    #     loc_index = location[0, length]
    #     country_code = GEO_DICTIONARY[loc_index]
    #     code = country_code unless country_code.nil?
    #   end
    #
    #   code = 'CN' if PROVINCE_DICTIONARY.keys.include?(location[0, 2])
    #   # code = location_to_country_code(location)
    #
    #   if code.nil? or code.length != 2
    #     @dislocated[ip] = location
    #     next
    #   else
    #     located_count += 1
    #     @located[ip] = location
    #     @areas[code] = {} if @areas[code].nil?
    #     @areas[code][:ips] = {} if @areas[code][:ips].nil?
    #     @areas[code][:ips][ip] = location
    #   end
    # end

    [{events: src_events, ip_type: 'src_ip'},
     {events: dst_events, ip_type: 'dst_ip'}].each do |hash|
      events = hash[:events]
      events.each do |event|
        ip = event.send(hash[:ip_type])
        next if ip == target_ip

        location = IP_LOCATION_SEEKER.seek(ip)
        # code = location_to_country_code(location)
        code = location[0, 2] if PROVINCE_DICTIONARY.keys.include?(location[0, 2])

        if code.nil? || code.length != 2
          @dislocated[ip] = location
          next
        else
          located_count += 1
          @located[ip] = location
          @areas[code] = {} if @areas[code].nil?
          @areas[code][:ips] = {} if @areas[code][:ips].nil?
          @areas[code][:ips][ip] = {location: location, count: 0} if @areas[code][:ips][ip].nil?
          @areas[code][:ips][ip][:count] += event.count
        end
      end
    end

    max_ip_count = (@areas.map {|code, area| area[:ips].length}).max
    @areas.each_value do |area|
      ip_count = area[:ips].count
      # ip_count = ip_count * 2 if ip_count < 3
      area[:saturation] = Math.log(ip_count, 10) * 90.0 / Math.log(max_ip_count, 10) + 10
      area[:thickness] = Math.log(ip_count, 10) * 5 + 1
    end

    @areas.each_value {|area| area[:description] = area[:ips].map {|ip, info| ip + ('&nbsp' * (20 - ip.length)) + ((info[:count] > 1) ? "(#{info[:count]})" : '&nbsp'*3) + ('&nbsp' * (7 - info[:count].to_s.length)) + info[:location] + '<br>'}.join}
    @located_description = @located.map {|ip, location| ip + ('&nbsp' * (20 - ip.length)) + location}
    # @areas.each_value { |area| area[:description] = area[:ips].map {|ip, location| "#{ip}#{' '*2*(17-ip.length)}#{location}\n"}.join }
    # @located_description = @located.map { |ip, location| "#{ip}#{' '*2*(19-ip.length)}#{location}" }
  end

  def china
    # target_ip = '125.219.116.29'

    # src_ips = Event.select('DISTINCT ip_src').collect { |event| event.src_ip }
    # dst_ips = Event.select('DISTINCT ip_dst').collect { |event| event.dst_ip }
    # @ips = (src_ips + dst_ips).uniq

    src_events = Event.select('DISTINCT ip_src, COUNT(ip_src) AS count').group(:ip_src)
    dst_events = Event.select('DISTINCT ip_dst, COUNT(ip_dst) AS count').group(:ip_dst)
    # src_ips = src_events.collect { |event| event.src_ip }
    # dst_ips = dst_events.collect { |event| event.dst_ip }

    @areas = {} if @areas.nil?
    @located = {} if @located.nil?
    @dislocated = {} if @dislocated.nil?

    located_count = 0
    # @ips.each do |ip|
    #   location = IP_LOCATION_SEEKER.seek(ip)
    #   code = location[0, 2] if PROVINCE_DICTIONARY.keys.include?(location[0, 2])
    #   # code = location_to_country_code(location)
    #
    #   if code.nil? or code.length != 2
    #     @dislocated[ip] = location
    #     next
    #   else
    #     located_count += 1
    #     @located[ip] = location
    #     @areas[code] = {} if @areas[code].nil?
    #     @areas[code][:ips] = {} if @areas[code][:ips].nil?
    #     @areas[code][:ips][ip] = location
    #   end
    # end

    [{events: src_events, ip_type: 'src_ip'},
     {events: dst_events, ip_type: 'dst_ip'}].each do |hash|
      events = hash[:events]
      events.each do |event|
        ip = event.send(hash[:ip_type])
        # next if ip == target_ip

        location = IP_LOCATION_SEEKER.seek(ip)
        # code = location_to_country_code(location)
        code = location[0, 2] if PROVINCE_DICTIONARY.keys.include?(location[0, 2])

        if code.nil? || code.length != 2
          @dislocated[ip] = location
          next
        else
          located_count += 1
          @located[ip] = location
          @areas[code] = {} if @areas[code].nil?
          @areas[code][:ips] = {} if @areas[code][:ips].nil?
          @areas[code][:ips][ip] = {location: location, count: 0} if @areas[code][:ips][ip].nil?
          @areas[code][:ips][ip][:count] += event.count
        end
      end
    end

    max_ip_count = (@areas.map {|code, area| area[:ips].length}).max
    @areas.each_value do |area|
      ip_count = area[:ips].count
      # ip_count = ip_count * 2 if ip_count < 3
      area[:saturation] = Math.log(ip_count, 10) * 90.0 / Math.log(max_ip_count, 10) + 10
      area[:thickness] = Math.log(ip_count, 10) * 5 + 1
    end

    @areas.each_value {|area| area[:description] = area[:ips].map {|ip, info| ip + ('&nbsp' * (20 - ip.length)) + ((info[:count] > 1) ? "(#{info[:count]})" : '&nbsp'*3) + ('&nbsp' * (7 - info[:count].to_s.length)) + info[:location] + '<br>'}.join}
    @located_description = @located.map {|ip, location| ip + ('&nbsp' * (20 - ip.length)) + location}
  end

end