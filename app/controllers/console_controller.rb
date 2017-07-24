class ConsoleController < ApplicationController

  def index
    # daily_data = ConsoleController.get_daily_data

    # New realtime data driver
    @realtime = ConsoleController.get_realtime_data
    @events = {
      level_low: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:low].join ', '})").order('timestamp DESC').limit(25),
      level_medium: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:medium].join ', '})").order('timestamp DESC').limit(25),
      level_high: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:high].join ', '})").order('timestamp DESC').limit(25)
    }
  end

  def daily
    daily_data = ConsoleController.get_daily_data([:level_low, :level_medium, :level_high], true)
    respond_to { |format| format.json { render json: daily_data } }
  end

  def realtime
    debug = false  # true

    realtime = {
      last_level_low: params[:last_level_low],
      last_level_medium: params[:last_level_medium],
      last_level_high: params[:last_level_high],
      # last_level_low: Time.new(params[:last_level_low]) + rand(300),
      # last_level_medium: Time.new(params[:last_level_medium]) + rand(300),
      # last_level_high: Time.new(params[:last_level_high]) + rand(300),


      last_level_low_cid: params[:last_level_low_cid],
      last_level_medium_cid: params[:last_level_medium_cid],
      last_level_high_cid: params[:last_level_high_cid],


      # original
      level_lows: [],
      level_mediums: [],
      level_highs: []

      # for DEBUG! Use with care
      # level_lows: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:low].join ', '})").order('timestamp DESC').limit(rand(3)),
      # level_mediums: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:medium].join ', '})").order('timestamp DESC').limit(rand(3)),
      # level_highs: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:high].join ', '})").order('timestamp DESC').limit(rand(3))
    }.merge(ConsoleController.get_realtime_data)

    if realtime[:last_level_low] != realtime[:latest_level_low] or realtime[:last_level_low_cid] != realtime[:latest_level_low_cid]
      realtime[:level_lows] += Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:low].join ', '}) AND (timestamp BETWEEN '#{next_second(realtime[:last_level_low])}' AND '#{realtime[:latest_level_low]}' OR cid > #{realtime[:last_level_low_cid]})")
    end
    if realtime[:last_level_medium] != realtime[:latest_level_medium] or realtime[:last_level_medium_cid] != realtime[:latest_level_medium_cid]
      realtime[:level_mediums] += Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:medium].join ', '}) AND (timestamp BETWEEN '#{next_second(realtime[:last_level_medium])}' AND '#{realtime[:latest_level_medium]}' OR cid > #{realtime[:last_level_medium_cid]})")
    end
    if realtime[:last_level_high] != realtime[:latest_level_high] or realtime[:last_level_high_cid] != realtime[:latest_level_high_cid]
      realtime[:level_highs] += Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:high].join ', '}) AND (timestamp BETWEEN '#{next_second(realtime[:last_level_high])}' AND '#{realtime[:latest_level_high]}' OR cid > #{realtime[:last_level_high_cid]})")
    end


    if debug
      realtime[:level_lows] += Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:low].join ', '})").order('timestamp DESC').limit(rand(3))
      realtime[:level_mediums] += Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:medium].join ', '})").order('timestamp DESC').limit(rand(3))
      realtime[:level_highs] += Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:high].join ', '})").order('timestamp DESC').limit(rand(3))
    end

    [:level_lows, :level_mediums, :level_highs].each do |type|
      realtime[type] = realtime[type].inject([]) do |collection, event|
        # src_ip = "#{rand(256)}.#{rand(256)}.#{rand(256)}.#{rand(256)}"
        # src_ip = event.src_ip
        src_ip = debug ? "#{rand(256)}.#{rand(256)}.#{rand(256)}.#{rand(256)}" : event.src_ip
        # dst_ip = "#{rand(256)}.#{rand(256)}.#{rand(256)}.#{rand(256)}"
        # dst_ip = event.dst_ip
        dst_ip = debug ? "#{rand(256)}.#{rand(256)}.#{rand(256)}.#{rand(256)}" : event.dst_ip

        src_location = IP_LOCATION_SEEKER.seek(src_ip)
        dst_location = IP_LOCATION_SEEKER.seek(dst_ip)
        src_country = location_to_country_code(src_location)
        dst_country = location_to_country_code(dst_location)
        # src_location = "#{src_location[0..15]}..." if src_location.length > 17
        src_location = "#{src_location[0..10]}..." if src_location.length > 12
        # dst_location = "#{dst_location[0..15]}..." if dst_location.length > 17
        dst_location = "#{dst_location[0..10]}..." if dst_location.length > 12

        occurred_at = event.timestamp.localtime.strftime('%H:%M')
        # occurred_at = realtime["last_#{type.to_s.singularize}".to_sym]

        sig_type = event.sig_type

        collection << event.attributes.merge(
          src_ip: src_ip,
          src_country: src_country,
          src_location: src_location,
          dst_ip: dst_ip,
          dst_country: dst_country,
          dst_location: dst_location,
          occurred_at: occurred_at,
          sig_type: sig_type
        )
      end
    end

    respond_to { |format| format.json { render json: realtime.to_json } }
  end

  def event
    @params = params
    id, type = params[:id], params[:type]
    return if id.nil? or type.nil?
    # TODO: add conditions to query events
    @msg = Event.where("cid = #{id}")[0]
  end

  def chart
    # TODO: change default_chart_name to the real one
    @chart_name = (params[:chart_name] or 'default_chart_name')
    @chart_action = (params[:chart_action] or 'init')
    global_chart_settings
    render "console/charts/#{@chart_name}/#{@chart_action}.js.erb"
  end

  private

  def self.get_daily_data(contents = [:level_low, :level_medium, :level_high], is_array = false)
    # today = Event.order(:timestamp).last.timestamp.localtime.to_date
    {
      '505' => {level_low: 80, level_medium: 80, level_high: 80, max: 80, ratio: 100.0},
      '509' => {level_low: 80, level_medium: 80, level_high: 80, max: 80, ratio: 100.0}
    }
  end

  def self.get_realtime_data
    realtime = {
      latest_level_low: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:low].join ', '})").select('timestamp').order('timestamp').last.timestamp.localtime.to_s(:db),
      latest_level_medium: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:medium].join ', '})").select('timestamp').order('timestamp').last.timestamp.localtime.to_s(:db),
      latest_level_high: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:high].join ', '})").select('timestamp').order('timestamp').last.timestamp.localtime.to_s(:db),
      latest_level_low_cid: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:low].join ', '})").select('cid').order('cid').last.cid,
      latest_level_medium_cid: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:medium].join ', '})").select('cid').order('cid').last.cid,
      latest_level_high_cid: Event.where("sig_class_id in (#{Event::SIG_LEVEL_IDS[:high].join ', '})").select('cid').order('cid').last.cid
    }
  end

  def next_second(time_string)
    (time_string.to_time + 1.second).to_s(:db)
  end

  def global_chart_settings
    @global_chart_settings = {
      chart: {
        bgAlpha: 0,
        canvasBgAlpha: 5,
        enableSmartLabels: 0,
        formatNumberScale: 0,
        labelSepChar: ': ',
        outCnvBaseFont: 'Microsoft Yahei',
        outCnvBaseFontSize: 13,
        outCnvBaseFontColor: 'FFFFFF',
        rotateLabels: 1,
        showBorder: 0,
        showPercentValues: 1,
        showZeroPies: 0,
        slantLabels: 1,
        smartLineColor: 'FFFFFF'
      },
      styles: {
        definition: [
          {
            bold: 1,
            color: '99FFFF',
            font: 'Microsoft Yahei',
            name: 'titleFont',
            shadow: 20,
            size: '18',
            type: 'font'
          },
          {
            bold: 1,
            color: 'FFFFFF',
            font: 'Microsoft Yahei',
            name: 'lableFont',
            size: '16',
            type: 'font'
          },
          {
            bold: 1,
            color: 'FFFFFF',
            name: 'valueFont',
            size: '13',
            type: 'font'
          },
          {
            bgColor: 'CC0000',
            color: 'FFFFFF',
            font: 'Microsoft Yahei',
            name: 'toolTipFont',
            size: '24',
            type: 'font'
          },
          {
            bold: 1,
            color: 'FFFF00',
            font: 'Microsoft Yahei',
            name: 'legendFont',
            size: '16',
            type: 'font'
          }
        ],
        application: [
          {
            styles: 'titleFont',
            toObject: 'Caption'
          },
          {
            styles: 'lableFont',
            toObject: 'DataLabels'
          },
          {
            styles: 'valueFont',
            toObject: 'DataValues'
          },
          {
            styles: 'toolTipFont',
            toObject: 'ToolTip'
          },
          {
            styles: 'legendFont',
            toObject: 'Legend'
          }
        ]
      }
    }
  end

  # TODO: Remove the duplications: here -> MapHelper#location_to_country_code(location)
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