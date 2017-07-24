# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


update_all_data = ->
  # update_bars_data()
  # update_map_data_demo()
  realtime_data_driver()

update_bars_data = ->
  $.getJSON '/console/daily.json', {}, (responses) ->
    has_new_level_low = has_new_level_medium = false
    for response in responses
      chartReference = FusionCharts("dept_bar_#{response.dept_code}")
      chartJSONData = chartReference.getJSONData()
      level_low_diff = response.level_low - parseInt(chartJSONData.data[0].value, 10)
      level_medium_diff = response.level_medium - parseInt(chartJSONData.data[1].value, 10)
      if level_low_diff isnt 0 or level_medium_diff isnt 0
        chartJSONData.chart.yaxismaxvalue = response.max
        # todo: update_yaxismaxvalue() if chartJSONData.chart.yaxismaxvalue isnt (response.max).toString()
        if level_low_diff isnt 0
          has_new_level_low = true
          chartJSONData.data[0].value = response.level_low
          chartJSONData.data[0].tooltext = chartJSONData.data[0].tooltext.replace(/\d+$/, response.level_low)
          # Show float message about level_low_inc
          floatMessage response.dept_code, 'level_low', level_low_diff, 500, 3000
          # Trigger 'clickMapObject' event to show animate on map
          map.clickMapObject map.getObjectById(response.dept_code)
        if level_medium_diff isnt 0
          has_new_level_medium = true
          chartJSONData.data[1].value = response.level_medium
          chartJSONData.data[1].tooltext = chartJSONData.data[1].tooltext.replace(/\d+$/, response.level_medium)
          # show float message about level_medium_inc
          floatMessage response.dept_code, 'level_medium', level_medium_diff, 500, 3000
        # Update dept_bar chart data
        chartReference.setJSONData(chartJSONData)
        $("#bar_#{response.dept_code}").effect('highlight', {color: 'hsl(120, 100%, 77%)'}, 1500)
        # Update dept_ratio_pie chart data
        update_dept_ratio_pie_data(response.dept_code, response.ratio)
    # Update charts data
    if has_new_level_low or has_new_level_medium # Update Bar2D、ScrollCombi2D、Radar data
      for chartName in ['level_low_level_medium_level_high_bur_bar2d', 'level_high_hour_scrollcombi2d', 'level_low_level_medium_dept_radar'] # 'level_low_level_medium_dept_msbar3d'
        ajaxCallChart(chartName)
    if has_new_level_low                  # Update Pie2D、Column2D data
      for chartName in ['level_low_meth_pie2d', 'level_low_dir_column2d'] # 'level_low_dept_pie2d', 'level_low_front_pie2d', 'level_low_dir_pie2d'
        ajaxCallChart(chartName)
    if has_new_level_medium                 # Update Pie2D 'level_medium'、'front' data
      for chartName in ['level_medium_dept_pie2d', 'level_high_front_pie2d']
        ajaxCallChart(chartName)

update_dept_ratio_pie_data = (dept_code, ratio) ->
  chartReference = FusionCharts("dept_pie_#{dept_code}")
  chartJSONData = chartReference.getJSONData()
  chartJSONData.data[0].value = ratio
  chartJSONData.data[0].tooltext = chartJSONData.data[0].tooltext.replace(/\d+\.?\d*/, ratio)
  chartJSONData.data[1].value = 100 - ratio
  chartJSONData.data[1].tooltext = chartJSONData.data[0].tooltext
  chartReference.setJSONData(chartJSONData)
  $("#pie_#{dept_code}").effect('highlight', {color: 'hsl(120, 100%, 77%)'}, 1500)

realtime_data_driver = ->
  b$ = $('#realtime b')
  $.getJSON '/console/realtime.json', {
    last_level_low: b$.get(0).textContent,
    last_level_medium: b$.get(1).textContent,
    last_level_high: b$.get(2).textContent,
    last_level_low_cid: b$.get(3).textContent,
    last_level_medium_cid: b$.get(4).textContent,
    last_level_high_cid: b$.get(5).textContent
  }, (response) ->
    update_scroll_event response.level_lows, 'level_low'
    update_scroll_event response.level_mediums, 'level_medium'
    update_scroll_event response.level_highs, 'level_high'

    $('#debug pre').html """
      <b>last_level_low:</b> #{response.last_level_low}
      <b>last_level_medium:</b> #{response.last_level_medium}
      <b>last_level_high:</b> #{response.last_level_high}<br>
      <b>last_level_low_cid:</b> #{response.last_level_low_cid}
      <b>last_level_medium_cid:</b> #{response.last_level_medium_cid}
      <b>last_level_high_cid:</b> #{response.last_level_high_cid}<br>
      <b>latest_level_low:</b> #{response.latest_level_low}
      <b>latest_level_medium:</b> #{response.latest_level_medium}
      <b>latest_level_high:</b> #{response.latest_level_high}<br>
      <b>latest_level_low_cid:</b> #{response.latest_level_low_cid}
      <b>latest_level_medium_cid:</b> #{response.latest_level_medium_cid}
      <b>latest_level_high_cid:</b> #{response.latest_level_high_cid}<br>
      <b>level_lows:</b> #{(level_low.sig_name for level_low in response.level_lows).join('<br />' + Array(8).join('&nbsp;'))}
      <b>level_mediums:</b> #{(level_medium.sig_name for level_medium in response.level_mediums).join('<br />' + Array(8).join('&nbsp;'))}
      <b>level_highs:</b> #{(level_high.sig_name for level_high in response.level_highs).join('<br />' + Array(8).join('&nbsp;'))}
      """
#    $("#debug").effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 1500)

    b$ = $('#realtime b')
    if response.latest_level_low isnt response.last_level_low
      b$.get(0).textContent = response.latest_level_low
      b$.eq(0).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)
    if response.latest_level_medium isnt response.last_level_medium
      b$.get(1).textContent = response.latest_level_medium
      b$.eq(1).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)
    if response.latest_level_high isnt response.last_level_high
      b$.get(2).textContent = response.latest_level_high
      b$.eq(2).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)
    if response.latest_level_low_cid.toString() isnt response.last_level_low_cid
      b$.get(3).textContent = response.latest_level_low_cid
      b$.eq(3).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)
    if response.latest_level_high_cid.toString() isnt response.last_level_high_cid
      b$.get(4).textContent = response.latest_level_high_cid
      b$.eq(4).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)

update_scroll_event = (events, type) ->
  ul$ = $("#scroll_event .#{type}")
  if events.length > 0
    list_array = ("<li data-id='#{event.cid}'><img src='/assets/#{randomIcon()}.png' class='device-type' width='128' height='128'><abbr><b>#{event.signature}</b></abbr><span>" +
      "<div class='ip-with-location'><img src='/images/flags_iso/64/#{event.src_country}.png' class='country' width='32' height='32'>" +
      "<p class='ip-address'>#{event.src_ip}</p><p class='location'>#{event.src_location}</p></div> <b class='glyphicon glyphicon-arrow-right'></b> " +
      "<div class='ip-with-location'><img src='/images/flags_iso/64/#{event.dst_country}.png' class='country' width='32' height='32'>" +
      "<p class='ip-address'>#{event.dst_ip}</p><p class='location'>#{event.dst_location}</p></div></span>" +
      "<span class='sig-name'>#{event.sig_name}</span><span class='timestamp'>#{event.occurred_at}</span><span class='sig-type'>#{event.sig_type}</span></li>" for event in events)
    lists$ = $(list_array.join '').prependTo(ul$).hide()
    lists_height = 0
    lists_height += $(list).height() + 25 for list in lists$ # li {... margin-top: 5px; padding: 10px;}, so +25
    ul$.animate {marginTop: lists_height + 'px'}, 1000, (msgs = lists$) ->
      $(@).css {marginTop: 0}
      msgs.fadeIn(500).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 1500) # fadeIn 1000
      $(@).children('li')[10..].fadeOut 1000, -> # [10..]
        $(@).remove()

update_map_data_demo = ->
  times = Math.round(Math.random() * 3)
  #  index = String(Math.round(Math.random() * (@provinces.length - 1)))
  #  id = 'CN-' + @provinces[index]
  #  @map.clickMapObject @map.getObjectById(id) #('CN-11')
  #  $('#map_china').effect('highlight', {color: 'hsl(120, 100%, 77%)'}, 1500)

  #  for i in [0..(@dept_codes.length-1)]
  #    dept = @dept_codes[i]
  #    @map.clickMapObject @map.getObjectById(dept)
  for i in [1..times]
    index = String(Math.round(Math.random() * (@dept_codes.length - 1)))
    dept = @dept_codes[index]
    @map.clickMapObject @map.getObjectById(dept)

#code_to_icon = (code) ->
#  code

randomIcon = ->
  icons = ['iPhone', 'iPad', 'iMac', 'MacBook', 'notebook', 'PC', 'phone', 'printer', 'router', 'broadcast']
  index = Math.floor(Math.random() * icons.length)
  icons[index]


fusionChart = (chartType, chartObject, chartJSONData, domContainer) ->
  myChart = new FusionCharts chartType, chartObject, '100%', '100%'
  myChart.setTransparent true
  myChart.configure 'LoadingText', '加载中'
  myChart.setJSONData chartJSONData
  myChart.render domContainer
  domContainer$ = $("##{domContainer}")
  caption = domContainer$.data('caption') or ''
  domContainer$.prepend("<h3>#{caption}</h3>")

# Called in views/console/charts/#{chart_name}/init.js.erb
@fusionChartInit = (chartName, chartJSONData) ->
  chartType = chartName.split('_').pop()
  chartObject = chartName + '_object'
  domContainer = chartName + '_container'
  chartReference = FusionCharts(chartObject)
  if chartReference is undefined    # Initial Chart
    fusionChart(chartType, chartObject, chartJSONData, domContainer)
  else                               # Update Chart with Highlight Effect
    chartReference.setJSONData(chartJSONData)
    $("##{domContainer}").effect('highlight', {color: 'hsl(120, 100%, 77%)'}, 1500)


ajaxCallChart = (chartName) ->
  $.getScript("/console/chart?chart_name=#{chartName}&chart_action=init")

bindDblClickToRefrenshChart = (chartName) ->
  $("##{chartName}_container").dblclick ->
    ajaxCallChart(chartName)

# Called in views/console/_dept_items.js.erb
@floatMessage = (deptCode, type, value, delay, keep) ->
  svg$ = $("#svg_number_template .#{type}").clone()
  msg = svg$.children().get(0).textContent + value
  svg$.children().get(0).textContent = msg
  svg$.children().get(1).textContent = msg
  svg$.appendTo "#number_#{deptCode}"
  svg$.delay delay
  svg$.animate {opacity: 'show', top: -20}, 'slow'
  svg$.delay keep
  svg$.fadeOut 'slow', ->
    $(@).remove()


$ ->
#  for chartName in ['level_low_level_medium_level_high_bur_bar2d', 'level_medium_dept_pie2d', 'level_high_front_pie2d', 'level_high_hour_scrollcombi2d', # 'level_low_dept_pie2d',
#    'level_medium_dir_dept_day_stackedbar2d', 'level_medium_dir_dept_week_stackedbar2d', 'level_medium_dir_dept_month_stackedbar2d', # 'level_medium_dir_dept_stackedbar2d',
#    'score_dept_mscombidy2d', 'score_old_dept_mscombi2d', # 'level_low_front_pie2d',
#    'level_low_meth_pie2d', 'level_low_dir_column2d', 'level_low_level_medium_dept_radar'] # 'level_low_level_medium_dept_msbar3d', 'sample_pie2d', 'level_low_dir_pie2d'
#    # Initial Charts
#    ajaxCallChart(chartName)
#    # Set Double Click Binding
#    bindDblClickToRefrenshChart(chartName)


  # Bind Click Event to Scroll Message Waterfall
  $('#scroll_message').click (event) ->

  # Enable Tabs
  items$ = $('#tabs>ul>li')
  items$.click -> #.mouseover
    items$.removeClass 'selected'
    $(@).addClass 'selected'
    index = items$.index $(@)
    #    $('#tabs>div').hide().eq(index).show()
    $('#tabs>div').css({top: 3000}).eq(index).css({top: 0})
  items$.eq(0).click() #.mouseover()

  # Enable Period-Select-Tabs for Charts "level_medium_dir_dept_[period]_stackedbar2d"
  periods$ = $('#period-select-tabs>ul>li')
  periods$.click -> #.mouseover
    periods$.removeClass 'selected'
    $(@).addClass 'selected'
    index = periods$.index $(@)
    [day_top, week_top, month_top] = switch index
      when 0 then [0, 3000, 3000]
      when 1 then [3000, 0, 3000]
      when 2 then [3000, 3000, 0]
    $('#level_medium_dir_dept_day_stackedbar2d_container').css({top: day_top})
    $('#level_medium_dir_dept_week_stackedbar2d_container').css({top: week_top})
    $('#level_medium_dir_dept_month_stackedbar2d_container').css({top: month_top})
  periods$.eq(0).click() #.mouseover()

  # Set Timer to update page via ajax, per 7s
  setInterval ( ->
    update_all_data() ), 7000

  # Set Timer to force refresh page, per 1 min
  setInterval ( ->
    location.reload(true) ), 60000

  # Footer Buttons
  #  $('#btn_enter_3wide').click ->
  #    $('#wrapper').css {width: '3072px'}
  win_width = $(window).width()
  $('#btn_home').click ->
    $('#wrapper').animate {marginLeft: '0px'}, 'slow', 'linear'
  $('#btn_left').click ->
    cur_margin = $('#wrapper').css('marginLeft').match(/^-?\d+\.?\d*/)
    cur_margin = parseInt(cur_margin, 10)
    next_margin = cur_margin + 60
    next_margin = 0 if next_margin > 0
    $('#wrapper').animate {marginLeft: "#{next_margin}px"}, 'fast', 'linear'
  $('#btn_center').click ->
    $('#wrapper').animate {marginLeft: "#{win_width / 2 - 1536}px"}, 'slow', 'linear'
  $('#btn_right').click ->
    cur_margin = $('#wrapper').css('marginLeft').match(/^-?\d+\.?\d*/)
    cur_margin = parseInt(cur_margin, 10)
    next_margin = cur_margin - 60
    next_margin = win_width - 3072 if next_margin < win_width - 3072
    $('#wrapper').animate {marginLeft: "#{next_margin}px"}, 'fast', 'linear'
  $('#btn_end').click ->
    $('#wrapper').animate {marginLeft: "#{win_width - 3072}px"}, 'slow', 'linear'

  # Footer Links
  $('#footer a').click ->
    $('#wrapper').css {marginLeft: '0px', width: '100%'}
    $('#footer').hide()