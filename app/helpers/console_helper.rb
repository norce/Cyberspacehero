module ConsoleHelper
  def code_to_icon(code)
    code
  end

  def svg_count_icon(count = 0)
    return if count == 0

    if count < 10
      x, y, font_family, font_size, font_weight = 31, 18, 'Arial', 18, 'normal'
    elsif count < 100
      x, y, font_family, font_size, font_weight = 28, 17, 'Arial', 14, 'bold'
    else
      x, y, font_family, font_size, font_weight = 26, 17, 'Impact', 13, 'normal'
    end

    <<END_OF_STRING
  <circle cx="36" cy="12" r="11" stroke="#eee" stroke-width="2" fill="url(#GradientCount)"></circle>
  <text x="#{x}" y="#{y}" font-family="#{font_family}" font-size="#{font_size}px" font-weight="#{font_weight}" fill="#eee">#{count}</text>
END_OF_STRING
  end

  def svg_number(type = :recv, number = '')
    y, fill, title = case type
                       when :recv then
                         [50, 'hsl(210, 50%, 70%)', '来报'] # 31
                       when :acpt then
                         [69, 'hsl(50, 100%, 40%)', '采用'] # 50
                     end
    <<END_OF_STRING
      <svg width="800" height="760" class="#{type}">
        <text x="1" y="#{y}" font-family="Microsoft Yahei" font-size="18" font-weight="bolder" stroke="hsl(0,100%,100%)" stroke-width="3" filter="url(#shadow)">#{title} +#{number}</text>
        <text x="1" y="#{y}" font-family="Microsoft Yahei" font-size="18" font-weight="bolder" fill="#{fill}">#{title} +#{number}</text>
      </svg>
END_OF_STRING

  end

  def svg_gradients
    <<END_OF_STRING
      <svg width="0" height="0" id="svg_gradients" >
        <linearGradient id="GradientDept" x="0" y="0" x2="0" y2="100%">
          <stop offset="0%" stop-color="hsl(0,100%,100%)"></stop>
          <stop offset="45%" stop-color="hsl(0,0%,90%)"></stop>
          <stop offset="55%" stop-color="hsl(0,0%,70%)"></stop>
          <stop offset="100%" stop-color="hsl(0,0%,60%)" stop-opacity="1"></stop>
        </linearGradient>

        <linearGradient id="GradientCount" x=0 y=0 x2=0 y2=100%>
          <stop offset="0%" stop-color="#fff"></stop>
          <stop offset="80%" stop-color="#f00" stop-opacity="1"></stop>
        </linearGradient>

        <defs>
          <filter id="shadow" x="0" y="0" width="200%" height="200%">
            <feOffset result="offOut" in="SourceAlpha" dx="4" dy="4" />
            <feGaussianBlur result="blurOut" in="offOut" stdDeviation="2" />
            <feBlend in="SourceGraphic" in2="blurOut" mode="normal" />
          </filter>
        </defs>
      </svg>
END_OF_STRING
  end

  def parse_msg(msg)
    #msg.gsub(/\r\n/, "┛\r\n").gsub(/ /, '·')    # msg.unpack('H*')[0]

    content = ''
    parts = msg.gsub(/[ ]{4}\r\n/, '').chomp.split "\r\n\r\n"
    parts[1..-1].each do |part|
      next if part !~ /^\s{4}/
      content = part
    end
    attrs = (parts - [content]).join("\r\n").split("\r\n")#.gsub(/\r\n/, ' | ')
    [attrs, content]
  end
end
