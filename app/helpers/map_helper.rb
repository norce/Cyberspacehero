module MapHelper
  def location_to_country_code(location)
    return '_Olimpic-Movement' if location.nil? or location.empty?

    # location.strip!

    [3, 2].each do |length|
      loc_index = location[0, length]
      country_code = GEO_DICTIONARY[loc_index]
      return country_code unless country_code.nil?
    end

    return 'CN' if PROVINCE_DICTIONARY.keys.include?(location[0, 2])

    return '_WHO'
  end
end
