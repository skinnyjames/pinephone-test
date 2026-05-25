class Hokusai::Blocks::Icon < Hokusai::Block
  template <<~EOF
  [template]
    virtual
  EOF

  MAP = {
    eyeclose: "\u{F070}",
    eye: "\u{F06E}",
    up: "\u{F106}",
    down: "\u{F107}",
    right: "\u{F105}",
    left: "\u{F104}",
    trash: "\u{F1F8}",
    add: "\u{F0FE}",
    hand: "\u{F256}",
    square: "\u{F0C8}",
    dropper: "\u{F1FB}",
    brush: "\u{F1FC}",
    folder_open: "\u{F07C}",
    grip: "\u{F58E}",
    save: "\u{F0C7}",
    blender: "\u{F517}",
    repeat: "\u{F363}",
    pointer: "\u{f245}",
    resize: "\u{f424}",
    phone: "\u{f095}",
    phoneoff: "\u{f3dd}",
    contact: "\u{f2bd}",
    home: "\u{f015}",
    batteryfull: "\u{f240}",
    batteryhalf: "\u{f242}",
    batteryempty: "\u{f244}",
    wifi: "\u{f1eb}",
    signal: "\u{f012}",
    power: "\u{f011}",
    sun: "\u{f185}",
    volume: "\u{f6a8}",
    deleteleft: "\u{f55a}",
  }

  computed! :type
  computed :size, default: 15, convert: proc(&:to_i)
  computed :color, default: Hokusai::Color.new(0, 0, 0), convert: Hokusai::Color
  computed :background, default: Hokusai::Color.new(255, 255, 255, 0), convert: Hokusai::Color
  computed :outline, default: Hokusai::Outline.default, convert: Hokusai::Outline
  computed :outline_color, default: Hokusai::Color.new(0, 0, 0, 0), convert: Hokusai::Color
  computed :padding, default: Hokusai::Padding.new(2.5, 5.0, 2.5, 5.0), convert: Hokusai::Padding
  computed :center, default: true

  def get_icon_from_type
    icon = MAP[type.to_sym]
    
    raise("No icon #{type}") if icon.nil?

    icon
  end

  def center_in(canvas, size)
    x = canvas.x + (canvas.width / 2.0) - ((size / 2) || 0.0)
    y = canvas.y + (canvas.height / 2.0) - ((size / 2) || 0.0)

    [x, y]
  end

  def render(canvas)
    if Hokusai.fonts.get("icons")
      draw do
        rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
          command.color = background
          command.outline = outline
          command.outline_color = outline_color
        end

        x, y = center_in(canvas, size)

        text(get_icon_from_type, x, y) do |command|
          command.padding = padding
          command.font = Hokusai.fonts.get("icons")
          command.size = size
          command.color = color
        end
      end

      yield canvas
    end
  end
end

class Time
  module StringFormatable

    AMPM   = %w(AM PM)
    DAYS   = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
    MONTHS = %w(January February March April May June July August September October November December)

    def strftime(format)
      format = format.dup
      while index = format.index('%') do
        f = format[index+1]
        break unless f

        format.gsub!("%#{f}", format_to_time(f))
      end
      format
    end

    private

    def format_to_time(f)
      case f
      when 'A', 'a'
        a = DAYS[wday]
        f == 'A' ? a : a[0..2]
      when 'B', 'b', 'h'
        m = MONTHS[month-1]
        f == 'B' ? m : m[0..2]
      when 'C'
        '%02d' % (year/100).to_i
      when 'c'
        '%a %b %e %H:%M:%S %Y'
      when 'D', 'x'
        '%m/%d/%y'
      when 'd', 'e'
        ( f == 'd' ? '%02d' : '%2d' ) % day
      when 'F'
        '%Y-%m-%d'
      when 'H', 'k'
        ( f == 'H' ? '%02d' : '%2d' ) % hour
      when 'I', 'l'
        v = hour
        v = 12  if v == 0
        v -= 12 if v > 12
        ( f == 'I' ? '%02d' : '%2d' ) % v
      when 'j'
        '%03d' % yday
      when 'L'
        '%03d' % ( usec / 1000 )
      when 'M'
        '%02d' % min
      when 'm'
        '%02d' % month
      when 'P', 'p'
        ampm = hour < 12 ? AMPM[0] : AMPM[1]
        f == 'p' ? ampm : ampm.downcase
      when 'R'
        '%H:%M'
      when 'r'
        '%I:%M:%S %p'
      when 'S'
        '%02d' % sec
      when 's'
        '%1d' % to_i
      when 'T', 'X'
        '%H:%M:%S'
      when 'u'
        '%1d' % ( sunday? ? 7 : wday )
      when 'v'
        '%e-%b-%Y'
      when 'w'
        '%1d' % wday
      when 'Y'
        '%04d' % year
      when 'y'
        '%02d' % ( year % 100 )
      when 'Z'
        zone
      when '%'
        '%'
      else
        ''
      end
    end
  end
end

class Time
  include StringFormatable
end

class Timer
  attr_accessor :start, :end

  def initialize
    @start = Hokusai.monotonic
    @end = @start
  end

  def elapsed?(seconds)
    return true if @end - @start > seconds
    
    false
  end

  def restart
    @start = Hokusai.monotonic
    @end = @start
  end

  def elapsed
    @end - @start
  end

  def next
    @end = Hokusai.monotonic
  end
end

class Hokusai::Blocks::Center < Hokusai::Block
  template <<~EOF
  [template]
    dynamic { @size_updated="update_size" }
      slot
  EOF

  attr_accessor :cwidth, :cheight

  uses(dynamic: Hokusai::Blocks::Dynamic)

  computed :horizontal, default: false
  computed :vertical, default: false

  def update_size(width, height)
    self.cwidth = width
    self.cheight = height
  end

  def render(canvas)
    a = cwidth ? cwidth / 2 : 0.0
    b = cheight ? cheight / 2 : 0.0

    canvas.x = canvas.x + (canvas.width / 2.0) - a if horizontal || (!horizontal && !vertical)
    canvas.y = canvas.y + (canvas.height / 2.0) - b if vertical || (!horizontal && !vertical)

    yield canvas
  end
end