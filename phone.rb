class PhoneContact < Hokusai::Block
  template <<-EOF
  [template]
    virtual
  EOF
end

class PhoneKey < Hokusai::Block
  template <<-EOF
  [template]
    empty {
      @tap="emit_clicked"
    }
  EOF

  uses(empty: Hokusai::Blocks::Empty)


  inject :theme
  computed! :key
  computed :size, default: 136, convert: proc(&:to_i)
  computed! :background

  def emit_clicked(event)
    emit(:clicked, event)
  end

  def centert(text, size, canvas)
    w, h = Hokusai.fonts.active.measure(text, size)
    hw = w / 2.0
    mid = canvas.x + canvas.width / 2
    midh = canvas.y + canvas.height / 2

    [mid - hw, midh - h / 2.0]
  end

  def render(canvas)
    x, y = centert(key[0], size, canvas)

    draw do
      rect(canvas.x, canvas.y, canvas.width, canvas.height) do |command|
        command.color = background
      end

      text(key[0], x, y - size / 4) do |command|
        command.size = size
        command.color = theme.light
      end

      if nums = key[1]
        nx, ny = centert(key[1], 34, canvas)

        text(nums, nx, y + size / 2 + 10) do |command|
          command.size =  34
          command.color = theme.light
        end
      end
    end

    yield canvas
  end
end

class PhoneDialer < Hokusai::Block
  style <<-EOF
  [style]
  phoneKey {
    width: 180.0;
    height: 180.0;
  }

  button {
    background: rgb(22,22,22);
  }

  buttonPrimary {
    background: rgb(45, 45, 45);
  }

  buttonSecondary {
    background: rgb(34, 34, 34);
  }

  phoneButton {
    background: rgb(0, 0, 0, 0);
  }

  phoneButton@click {
    background: rgb(22,22,222);
  }
  EOF
  
  template do
    child(Hokusai::Blocks::Vblock) do
      prop :background do
        theme.dark
      end

      prop :padding do
        Hokusai::Padding.new(20.0, 0.0, 60.0, 80.0)
      end

      child(Hokusai::Blocks::Vblock) do
        prop :background do
          case call_status
          when :inactive
            [0, 0, 0, 0]
          when :pending
            theme.mainalt
          when :active
            theme.main
          end
        end

        prop :padding do
          Hokusai::Padding.new(90.0, 0.0, 0.0, 30.0)
        end

        static :width, "540.0"

        child(Hokusai::Blocks::Text) do
          prop :content do
            a = dialing.join("")
            a.empty? ? " " : a
          end
    
          prop :size do
            theme.large
          end
        end
      end

      child(Hokusai::Blocks::Vblock) do
        static :height, "720.0"
        static :width, "540.0"

        child(Hokusai::Blocks::Hblock) do
          static :wrap, "true"

          each_child(PhoneKey, :keys) do |key|
            static :cursor, "'pointer'"
            prop :key do
              key.value
            end

            prop :size do
              theme.med
            end

            prop :background do
              if bg = backgrounds.shift
                Hokusai::Color.new(0, 0, 0, bg)
              elsif colors[key.value[0]]
                colors.clear
                theme.mainalt
              else
                Hokusai::Color.new(0, 0, 0, 0)
              end
            end

            on :clicked do
              @colors[key.value[0]] = true
              dialing << key.value[0]
            end
            
            merge_styles "phoneKey"
          end
        end 
      end

      # Dial buttons
      child(Hokusai::Blocks::Vblock) do
        prop :height do
          90.0
        end

        child(Hokusai::Blocks::Center) do
          child(Hokusai::Blocks::Hblock) do
            merge_styles "button", "buttonPrimary"
            static "height", "90.0"
            static "width", "180.0"
            merge_styles "phoneButton"

            child(Hokusai::Blocks::Icon) do
              prop :size do
                theme.med
              end

              prop :type do
                :phone
              end

              on :tap do |event|
                emit("dial", dialing.join(""))
                self.call_status = :active
              end

              prop :color do
                theme.light
              end
            end

            child(Hokusai::Blocks::Icon) do
              static :type, "'deleteleft'"

              on :tap do |event|
                dialing.pop  
              end

              prop :size do
                theme.med
              end

              prop :color do
                theme.light
              end
            end
          end
        end
      end

      # Menu
      child(Hokusai::Blocks::Hblock) do
        prop :height do
          65.0
        end

        child(Hokusai::Blocks::Vblock) do
          child(Hokusai::Blocks::Icon) do
            static :size, "15"
            prop :type do
              :home
            end

            prop :color do
              theme.main
            end
          end
        end
        child(Hokusai::Blocks::Vblock) do
          child(Hokusai::Blocks::Icon) do
            static :size, "15"
            prop :type do
              :contact
            end

            prop :color do
              theme.light
            end
          end
        end
      end
    end
  end

  inject :theme
  attr_accessor :call_status, :dialing

  def keys
    [
      %w[1 abc],
      %w[2 efg],
      %w[3 hij],
      %w[4 klm],
      %w[5 nop],
      %w[6 qrs],
      %w[7 tuv],
      %w[8 wxy],
      %w[9 z],
      ["*", nil],
      ["0", nil],
      ["#", nil]
    ]
  end

  def colors
    @colors ||= {}
  end

  def backgrounds
    @bgs ||= (0..12).map do |i|
      255 - (i * 10 * 2)
    end.to_a * 10

    @bgs
  end

  def contacts
    %w[Janesso Sean Bob Helen]
  end

  def initialize(**args)
    @call_status = :inactive
    @dialing = []

    super
  end
end

class PhoneAvatar < Hokusai::Block
  style <<~EOF
  [style]
  contactIcon {
    width: 136;
    height: 136;
  }
  EOF

  inject :theme
  attr_accessor :circles

  template do
    child(Hokusai::Blocks::Icon) do
      static :type, "'contact'"

      merge_styles "contactIcon"

      prop :color do
        theme.light
      end

      prop :size do
        theme.xlarge
      end

      prop :color do
        theme.dark
      end

      on :tap do
        emit("disconnect")
      end
    end
  end

  def on_mounted
    node.meta.set_prop(:width, 136.0)
    node.meta.set_prop(:height, 136.0)
  end

  def render(canvas)
    if @timer.elapsed? 1
      4.times do |i|
        t = Timer.new
        t.start += i * 0.4
        circles << t

      end
      @timer.restart
    end

    sx = canvas.x + canvas.width / 2.0
    sy = canvas.y + canvas.height / 2.0
    base = theme.xlarge

    draw do
      circles.select! do |timer|
        size = base + 100 * timer.elapsed
        alpha = 200 * timer.elapsed
        timer.next
        if timer.elapsed? 1 || alpha >= 200 || size >= 226.0
          false
        else
          circle(sx, sy, size) do |command|
            command.color = Hokusai::Color.new(225, 225, 225, 225 - alpha)
          end

          true
        end
      end
    end

    @timer.next
    yield canvas
  end

  def initialize(**args)
    @circles = []
    @timer = Timer.new
    super
  end
end

class PhoneCall < Hokusai::Block
  template do
    # information
    child(Hokusai::Blocks::Vblock) do
      prop :background do
        theme.dark
      end

      child(Hokusai::Blocks::Center) do
        child(PhoneAvatar) do
          on :disconnect do
            emit :disconnect
          end
        end
      end
    end

    # actions
    child(Hokusai::Blocks::Vblock) do
      prop :background do
        theme.dark
      end
      child(Hokusai::Blocks::Empty) do
      end
    end
  end

  inject :theme
end

class Phone < Hokusai::Block
  template <<~EOF
  [template]
  vblock
    [if="active"]
      call { @disconnect="deactivate" }
    [else]
      dialer { @dial="activate" }
  EOF

  uses(
    vblock: Hokusai::Blocks::Vblock,
    dialer: PhoneDialer,
    call: PhoneCall,
  )

  provide :active, :active

  attr_accessor :active

  def deactivate
    self.active = false
   p ["ending #{@id}"]
    @buzz.call("EndFeedback", [@id])
  end

  def activate(number)
    self.active = true
    @id ||= @buzz.call("TriggerFeedback", ["test", "phone-incoming-call", {}, 20])
  end

  def initialize(**args)
    @active = false
    @buzz = SDBus.user.service("org.sigxcpu.Feedback")
			.object("/org/sigxcpu/Feedback")
			.interface("org.sigxcpu.Feedback")      

    super
  end
end
