require_relative "./patches"
require_relative "./menu"
require_relative "./theme"
require_relative "./phone"

class App < Hokusai::Block
  template <<-EOF
  [template]
  vblock
    [if="status_active"]
      statusmenu { @close="deactivate_menu" }
    [else]
      statusbar { @open="activate_menu" }
    phone
  EOF

  uses(
    vblock: Hokusai::Blocks::Vblock,
    phone: Phone, 
    statusbar: StatusBar,
    statusmenu: StatusMenu
  )

  provide :theme, :theme
  provide :current_time, :current_time

  attr_accessor :status_active

  def theme
    @theme ||= Theme.init
  end

  def current_time
    Time.now.strftime("%b %e %Y @ %l:%M %p")
  end

  def activate_menu
    self.status_active = true
  end

  def deactivate_menu
    self.status_active = false
  end

  def initialize(**args)
    @status_active = false

    super
  end
end

Hokusai::Backend.run(App) do |config|
  config.title = "OS Idea"
  config.fps = 60
  config.width = 720 
  config.height = 1400 
  config.config_flags = HP_FLAG_VSYNC_HINT
  config.audio = false
  config.touch = true
  config.event_waiting = false

  config.after_load do
    Hokusai.fonts.register "default", Hokusai::Backend::Font.from_ext("assets/boldy.ttf", 34 * 4)
    Hokusai.fonts.activate "default"

    Hokusai.fonts.register "icons", Hokusai::Backend::Font.from_ext("assets/fa2.ttf", 34 * 4, Hokusai::Blocks::Icon::MAP.values.join(""))
  end
end
