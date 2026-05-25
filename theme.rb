class Theme
  def self.init
    obj = new

    file = File.read("theme.txt")
    file.split("\n").each do |line|
      key, val = line.split(":")
    
      obj.send("#{key}=", Hokusai::Color.convert(val))
    end

    file = File.read("theme_size.txt")
    file.split("\n").each do |line|
      key, val = line.split(":")
    
      obj.send("#{key}=", val.to_i)
    end

    obj
  end

  attr_accessor :dark, :main, :mainalt, :light, :xsmall, :small, :med, :large, :xlarge
end