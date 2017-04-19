# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/


update_all_data = ->
  # update_bars_data()
  # update_map_data_demo()
  # realtime_data_driver()

update_bars_data = ->
  $.getJSON '/console/daily.json', {}, (responses) ->
    has_new_recv = has_new_acpt = false
    for response in responses
      chartReference = FusionCharts("dept_bar_#{response.dept_code}")
      chartJSONData = chartReference.getJSONData()
      recv_diff = response.recv - parseInt(chartJSONData.data[0].value, 10)
      acpt_diff = response.acpt - parseInt(chartJSONData.data[1].value, 10)
      if recv_diff isnt 0 or acpt_diff isnt 0
        chartJSONData.chart.yaxismaxvalue = response.max
        # todo: update_yaxismaxvalue() if chartJSONData.chart.yaxismaxvalue isnt (response.max).toString()
        if recv_diff isnt 0
          has_new_recv = true
          chartJSONData.data[0].value = response.recv
          chartJSONData.data[0].tooltext = chartJSONData.data[0].tooltext.replace(/\d+$/, response.recv)
          # Show float message about recv_inc
          floatMessage response.dept_code, 'recv', recv_diff, 500, 3000
          # Trigger 'clickMapObject' event to show animate on map
          map.clickMapObject map.getObjectById(response.dept_code)
        if acpt_diff isnt 0
          has_new_acpt = true
          chartJSONData.data[1].value = response.acpt
          chartJSONData.data[1].tooltext = chartJSONData.data[1].tooltext.replace(/\d+$/, response.acpt)
          # show float message about acpt_inc
          floatMessage response.dept_code, 'acpt', acpt_diff, 500, 3000
        # Update dept_bar chart data
        chartReference.setJSONData(chartJSONData)
        $("#bar_#{response.dept_code}").effect('highlight', {color: 'hsl(120, 100%, 77%)'}, 1500)
        # Update dept_ratio_pie chart data
        update_dept_ratio_pie_data(response.dept_code, response.ratio)
    # Update charts data
    if has_new_recv or has_new_acpt # Update Bar2D、ScrollCombi2D、Radar data
      for chartName in ['recv_acpt_sent_bur_bar2d', 'sent_hour_scrollcombi2d', 'recv_acpt_dept_radar'] # 'recv_acpt_dept_msbar3d'
        ajaxCallChart(chartName)
    if has_new_recv                  # Update Pie2D、Column2D data
      for chartName in ['recv_meth_pie2d', 'recv_dir_column2d'] # 'recv_dept_pie2d', 'recv_front_pie2d', 'recv_dir_pie2d'
        ajaxCallChart(chartName)
    if has_new_acpt                 # Update Pie2D 'acpt'、'front' data
      for chartName in ['acpt_dept_pie2d', 'sent_front_pie2d']
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
    last_recv: b$.get(0).textContent,
    last_acpt: b$.get(1).textContent,
    last_sent: b$.get(2).textContent,
    last_recv_xh: b$.get(3).textContent,
    last_sent_xh: b$.get(4).textContent
  }, (response) ->
    update_scroll_message response.recvs, 'recv'
    update_scroll_message response.acpts, 'acpt'
    update_scroll_message response.sents, 'sent'

    $('#debug pre').html """
      last_recv: #{response.last_recv}
      last_acpt: #{response.last_acpt}
      last_sent: #{response.last_sent}
      last_recv_xh: #{response.last_recv_xh}
      last_sent_xh: #{response.last_sent_xh}
      latest_recv: #{response.latest_recv}
      latest_acpt: #{response.latest_acpt}
      latest_sent: #{response.latest_sent}
      latest_recv_xh: #{response.latest_recv_xh}
      latest_sent_xh: #{response.latest_sent_xh}
      recvs: #{(recv.BT for recv in response.recvs).join('<br />' + Array(8).join('&nbsp;'))}
      acpts: #{(acpt.BT for acpt in response.acpts).join('<br />' + Array(8).join('&nbsp;'))}
      sents: #{(sent.BT for sent in response.sents).join('<br />' + Array(8).join('&nbsp;'))}
      """
    $("#debug").effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 1500)

    b$ = $('#realtime b')
    if response.latest_recv isnt response.last_recv
      b$.get(0).textContent = response.latest_recv
      b$.eq(0).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)
    if response.latest_acpt isnt response.last_acpt
      b$.get(1).textContent = response.latest_acpt
      b$.eq(1).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)
    if response.latest_sent isnt response.last_sent
      b$.get(2).textContent = response.latest_sent
      b$.eq(2).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)
    if response.latest_recv_xh.toString() isnt response.last_recv_xh
      b$.get(3).textContent = response.latest_recv_xh
      b$.eq(3).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)
    if response.latest_sent_xh.toString() isnt response.last_sent_xh
      b$.get(4).textContent = response.latest_sent_xh
      b$.eq(4).effect('highlight', {color: 'hsl(180, 100%, 70%)'}, 10000)

update_scroll_message = (messages, type) ->
  ul$ = $("#scroll_message .#{type}")
  if messages.length > 0
    list_array = ("<li data-id='#{message.XH}'><span><b>#{code_to_icon(message.DWDM)}</b></span><p>#{message.BT}</p></li>" for message in messages)
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

code_to_icon = (code) ->
  code


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
#  for chartName in ['recv_acpt_sent_bur_bar2d', 'acpt_dept_pie2d', 'sent_front_pie2d', 'sent_hour_scrollcombi2d', # 'recv_dept_pie2d',
#    'acpt_dir_dept_day_stackedbar2d', 'acpt_dir_dept_week_stackedbar2d', 'acpt_dir_dept_month_stackedbar2d', # 'acpt_dir_dept_stackedbar2d',
#    'score_dept_mscombidy2d', 'score_old_dept_mscombi2d', # 'recv_front_pie2d',
#    'recv_meth_pie2d', 'recv_dir_column2d', 'recv_acpt_dept_radar'] # 'recv_acpt_dept_msbar3d', 'sample_pie2d', 'recv_dir_pie2d'
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

  # Enable Period-Select-Tabs for Charts "acpt_dir_dept_[period]_stackedbar2d"
  periods$ = $('#period-select-tabs>ul>li')
  periods$.click -> #.mouseover
    periods$.removeClass 'selected'
    $(@).addClass 'selected'
    index = periods$.index $(@)
    [day_top, week_top, month_top] = switch index
      when 0 then [0, 3000, 3000]
      when 1 then [3000, 0, 3000]
      when 2 then [3000, 3000, 0]
    $('#acpt_dir_dept_day_stackedbar2d_container').css({top: day_top})
    $('#acpt_dir_dept_week_stackedbar2d_container').css({top: week_top})
    $('#acpt_dir_dept_month_stackedbar2d_container').css({top: month_top})
  periods$.eq(0).click() #.mouseover()

  # Set Timer to update page via ajax, per 7s
  setInterval ( ->
    update_all_data() ), 7000

  # Set Timer to force refresh page, per 10min
  setInterval ( ->
    location.reload(true) ), 600000

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