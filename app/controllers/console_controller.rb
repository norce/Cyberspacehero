class ConsoleController < ApplicationController

  def index
    # daily_data = ConsoleController.get_daily_data

    # New realtime data driver
    @realtime = ConsoleController.get_realtime_data
    @events = {
      recv: Event.order('timestamp DESC').limit(25),
      acpt: Event.order('timestamp DESC').limit(25),
      sent: Event.order('timestamp DESC').limit(25)
    }
  end

  def daily
    daily_data = ConsoleController.get_daily_data([:recv, :acpt], true)
    respond_to { |format| format.json { render json: daily_data } }
  end

  def realtime
    realtime = {
      last_recv: params[:last_recv],
      last_acpt: params[:last_acpt],
      last_sent: params[:last_sent],
      last_recv_xh: params[:last_recv_xh],
      last_sent_xh: params[:last_sent_xh],

      # original
      # recvs: [],
      # acpts: [],
      # sents: []

      # for DEBUG! Use with care
      recvs: Event.order('timestamp DESC').limit(rand(3)),
      acpts: Event.order('timestamp DESC').limit(rand(3)),
      sents: Event.order('timestamp DESC').limit(rand(3))
    }.merge(ConsoleController.get_realtime_data)
    if true # realtime[:last_recv] != realtime[:latest_recv] or realtime[:last_recv_xh] != realtime[:latest_recv_xh]
      realtime[:recvs] += Event.where("timestamp BETWEEN '#{next_second(realtime[:last_recv])}' AND '#{realtime[:latest_recv]}' OR cid > #{realtime[:last_recv_xh]}")
    end
    if true # realtime[:last_acpt] != realtime[:latest_acpt]
      realtime[:acpts] += Event.where("timestamp BETWEEN '#{next_second(realtime[:last_acpt])}' AND '#{realtime[:latest_acpt]}'")
    end
    if true # realtime[:last_sent] != realtime[:latest_sent] or realtime[:last_sent_xh] != realtime[:latest_sent_xh]
      realtime[:sents] += Event.where("timestamp BETWEEN '#{next_second(realtime[:last_sent])}' AND '#{realtime[:latest_sent]}' OR cid > #{realtime[:last_sent_xh]}")
    end

    respond_to { |format| format.json { render json: realtime.to_json } }
  end

  def message
    @params = params
    id, type = params[:id], params[:type]
    return if id.nil? or type.nil?
    @model = (type == 'sent') ? Sent : Recv
    @msg = @model.where("XH = #{id}")[0]
  end

  def chart
    @chart_name = (params[:chart_name] or 'recv_dept_pie2d')
    @chart_action = (params[:chart_action] or 'init')
    global_chart_settings
    render "console/charts/#{@chart_name}/#{@chart_action}.js.erb"
  end

  private

  def self.get_daily_data(contents = [:recv, :acpt], is_array = false)
    # today = Event.order(:timestamp).last.timestamp.localtime.to_date
    {
      '505' => {recv: 80, apct: 80, max: 80, ratio: 100.0},
      '509' => {recv: 80, apct: 80, max: 80, ratio: 100.0}
    }
  end

  def self.get_realtime_data
    realtime = {
      latest_recv: Event.select('timestamp').order('timestamp').last.timestamp.localtime.to_s(:db),
      latest_acpt: Event.select('timestamp').order('timestamp').last.timestamp.localtime.to_s(:db),
      latest_sent: Event.select('timestamp').order('timestamp').last.timestamp.localtime.to_s(:db),
      latest_recv_xh: Event.select('cid').order('cid').last.cid,
      latest_sent_xh: Event.select('cid').order('cid').last.cid
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
end