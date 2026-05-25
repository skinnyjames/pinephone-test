
module Hokusai::Blocks
  class Slider < Hokusai::Block
    style <<~EOF
    [style]
    cursorStyle {
      cursor: "pointer";
    }
    EOF
  
    template <<~EOF
    [template]
      empty {
        ...cursorStyle
        @tap="start_slider"
        @taphold="move_slider"
        @mouseup="stop_slider"
      }
    EOF

    uses(empty: Hokusai::Blocks::Empty)

    computed :fill, default: [61,171,211], convert: Hokusai::Color
    computed :background, default: [33,33,33], convert: Hokusai::Color
    computed :circle_color, default: [244,244,244], convert: Hokusai::Color
    computed :initial, default: 0, convert: proc(&:to_i)
    computed :size, default: 20.0, convert: proc(&:to_f)
    computed :step, default: 20, convert: proc(&:to_i)
    computed :min, default: 0, convert: proc(&:to_i)
    computed :max, default: 100, convert: proc(&:to_i)
    computed :padding, default: [10.0, 10.0, 0.0, 10.0], convert: Hokusai::Padding

    attr_reader :slider_width, :slider_start, :steps_x, :steps_val
    attr_accessor :sliding, :slider_x, :last_index

    def initialize(**args)
      @sliding = false
      @slider_width = 0.0
      @slider_start = 0.0
      @slider_x = 0.0
      @last_index = 0
      @configured = false

      super

      @last_max = nil
    end

    def prevent(event)
      event.stop
    end

    def start_slider(event)
      self.sliding = true
      event.stop
    end

    # step can be a float
    def steparr(min, max, step, edge = 0)
      nums = [min]
      while min < max
        if min + step > max
          nums[-1] = max - edge
        else
          nums << min + step
        end
  
        min = min + step 
      end
      nums
    end

    def on_resize(canvas)
      # create our buckets for steps
      @slider_start = canvas.x.to_i + padding.left.to_i
      @slider_width = canvas.width - padding.width

      sw = slider_width - (size / 2)

      valarr = steparr(min, max, step)
      sx = sw / (valarr.size.to_f - 1)
      xarr = steparr(slider_start.to_f, slider_start + sw, sx, size / 2.0)

      @steps_x = xarr
      @steps_val = valarr
    end

    def move_slider(event)
      if sliding
        pos = event.pos.x
        index = steps_x.size - 1
    
        (0...steps_x.size - 1).each do |i|
          if steps_x[i + 1] && pos - steps_x[i + 1] > step && i < steps_val.size - 1
            next
          end

          if pos - steps_x[i] > pos - steps_x[i + 1]
            index = i
            break 
          else
            if i < steps_val.size 
              index = i + 1
            end
            break
          end
        end

        if last_index != index
          emit("change", steps_val[index])
        end
        event.stop
        self.last_index = index unless index >= steps_val.size || steps_val[index].nil?
      end
    end

    def stop_slider(event)
      if event.left.up
        self.sliding = false
      end

      # event.stop
    end

    #        ┌───────────────────── canvas.width ──────────────────────┐    
    #        │                                                         │    
    #        │   ┌────────────────────────────────────────────────┐    │    
    #            │slider_width = canvas.width - slider_start - padding.right
    #        ┌───┴────────────────────────────────────────────────┴────┐    
    #        │                                                         │    
    #        │   ┌────────────xxxx────────────────────────────────┐    │    
    #        │   │           xxxxxx                               │    │    
    #        │   │      │    xxxxxx                               │    │    
    #        │   └──────┼─────xxxx────────────────────────────────┘    │    
    #        │          │      │                                       │    
    #        ├───┬──────┼──────┼───────────────────────────────────────┘    
    #        │   │      │      │                                            
    #        │   │      │      │                                            
    #        ▼   │      │      └► cursor_x                                  
    # canvas.x   │      │                                                   
    #            │      │                                                   
    #            │      │   slider_start = canvas.x + padding.left          
    #        ┌───┤      │                                                   
    #        │   │      │                                                   
    #        ▼   ▼      │                                                   
    #    padding.left   │                                                   
    #                   └────────► fill_x = slider_start
    #                              fill_w = slider_x - slider_start + padding.width 
    def render(canvas)
      if max != @last_max
        on_resize(canvas)

        @last_max = max
      end

      unless @setup || steps_val.nil? || initial.nil?
        steps_val.each_with_index do |val, index|
          if val == initial
            self.last_index = index

            break
          end
        end

        @setup = true
      end

      slider_x = steps_x[last_index]
      cursor = slider_x + (size / 2)
      cslider_width = slider_x - slider_start + padding.width

      draw do
        # slider background
        rect(slider_start, canvas.y + padding.top, slider_width, size) do |command|
          command.round = size / 2
          command.color = background
        end

        # slider fill
        rect(slider_start, canvas.y + padding.top, cslider_width, size) do |command|
          command.round = size / 2
          command.color = fill
        end

        if sliding
          circle(cursor, canvas.y + padding.top + (size / 2), size) do |command|
            command.color = Hokusai::Color.new(circle_color.r, circle_color.g, circle_color.b, 50)
          end
        end

        circle(cursor, canvas.y + padding.top + (size / 2), size / 2) do |command|
          command.color = circle_color
        end
      end

      yield canvas
    end
  end
end

class StatusMenu < Hokusai::Block
  style <<-EOF
  [style]
  style {
    z: 1;
    ztarget: "parent";
    background: rgb(0,0,0);
    cursor: "pointer";
  }
  icon {
    width: 40.0;
    height: 40.0;
    size: 34;
    color: rgb(255,255,255);
  }
  padded {
    padding: padding(20.0, 0.0, 0.0, 20.0);
    width: 70.0;
  }
  EOF

  template <<-EOF
  [template]
    vblock { ...style }
      vblock { :height="80.0" }
        text { :content="current_time" size="12" }
      hblock { :height="80.0" }
        vblock { ...padded }
          icon { type="sun" ...icon }
        slider { @change="update_bright" min="0" max="100" step="1" }
      hblock { :height="80.0" }
        vblock { ...padded }
          icon { type="signal" ...icon }
        slider { min="0" max="100" step="1" }
  EOF

  uses(
    vblock: Hokusai::Blocks::Vblock,
    hblock: Hokusai::Blocks::Hblock,
    empty: Hokusai::Blocks::Empty,
    text: Hokusai::Blocks::Text,
    slider: Hokusai::Blocks::Slider,
    icon: Hokusai::Blocks::Icon,
  )

  inject :current_time

  def update_bright(val)
    @val ||= val
    if val < @val
     p  bright.call("StepDown")
    else
    p  bright.call("StepUp")
    end
  end

  def emit_close(event)
    self.closing = true
    self.timer = Timer.new
  end

  def on_mounted
    node.meta.set_prop(:z, nil)
    node.meta.set_prop(:height, 0)
  end

  def render(canvas)
    if @timer.elapsed?(0.2) && !closing
      node.meta.set_prop(:z, 2)
      node.meta.set_prop(:ztarget, "root")
    elsif !closing
      height = canvas.oheight * (@timer.elapsed * 5)
      node.meta.set_prop(:height, height)
      @timer.next
    elsif timer.elapsed? 0.2
      emit("close")
    else
      node.meta.set_prop(:z, nil)

      height = canvas.oheight * (timer.elapsed * 5)
      node.meta.set_prop(:height, canvas.oheight - height)
      @timer.next
    end

    yield canvas
  end

  attr_accessor :timer, :closing, :bright

  def initialize(**args)
    @timer = Timer.new
    @closing = false
    @bright = SDBus.user.service("org.gnome.SettingsDaemon.Power")
			.object("/org/gnome/SettingsDaemon/Power")
			.interface("org.gnome.SettingsDaemon.Power.Screen")
    super
  end
end

class StatusBar < Hokusai::Block
  style <<-EOF
  [style]
  style {
    color: rgb(255,255,255);
    size: 14;
    width: 23.0;
  }
  labelContainer {
    padding: padding(10.0, 0.0, 0.0, 15.0);
  }
  labelStyle {
    color: rgb(255,255,255);
    size: 14;
  }
  background {
    background: rgb(0,0,0);
    cursor: "pointer";
  }
  EOF
  template <<-EOF
  [template]
  hblock { ...background  @tap="emit_open" }
    vblock { ...labelContainer }
      text { :content="current_time"  ...labelStyle }
    hblock { :width="86.0" }
      icon { type="signal" ...style }
      icon { type="wifi" ...style }
      icon { type="batteryfull" ...style }
  EOF

  uses(
    hblock: Hokusai::Blocks::Hblock,
    vblock: Hokusai::Blocks::Vblock,
    text: Hokusai::Blocks::Label,
    icon: Hokusai::Blocks::Icon
  )

  inject :current_time

  def emit_open(event)
    emit("open")
  end

  def on_mounted
    node.meta.set_prop(:height, 35.0)
  end
end
