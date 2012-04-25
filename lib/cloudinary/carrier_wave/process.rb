module Cloudinary::CarrierWave
  module ClassMethods
    def eager
      process :eager => true
    end
    
    def convert(format)
      process :convert => format
    end
  
    def resize_to_limit(width, height)
      process :resize_to_limit => [width, height]
    end
  
    def resize_to_fit(width, height)
      process :resize_to_fit => [width, height]
    end
  
    def resize_to_fill(width, height, gravity="Center")
      process :resize_to_fill => [width, height, gravity]
    end
  
    def resize_and_pad(width, height, background=:transparent, gravity="Center")
      process :resize_and_pad => [width, height, background, gravity]
    end    
  
    def scale(width, height)
      process :scale => [width, height]
    end    
  
    def crop(width, height, gravity="Center")
      process :crop => [width, height, gravity]
    end
  
    def cloudinary_transformation(options)
      process :cloudinary_transformation => options
    end
    
    def tags(*tags)
      process :tags=>tags
    end
  end

  def set_or_yell(hash, attr, value)
    raise "conflicting transformation on #{attr} #{value}!=#{hash[attr]}" if hash[attr]
    hash[attr] = value
  end
  
  def transformation
    return @transformation if @transformation
    @transformation = {}
    self.class.processors.each do
      |name, args|
      case name
      when :convert # Do nothing. This is handled by format
      when :resize_to_limit 
        set_or_yell(@transformation, :width, args[0])    
        set_or_yell(@transformation, :height, args[1])
        set_or_yell(@transformation, :crop, :limit)
      when :resize_to_fit 
        set_or_yell(@transformation, :width, args[0])    
        set_or_yell(@transformation, :height, args[1])
        set_or_yell(@transformation, :crop, :fit)
      when :resize_to_fill
        set_or_yell(@transformation, :width, args[0])    
        set_or_yell(@transformation, :height, args[1])
        set_or_yell(@transformation, :gravity, args[2].to_s.downcase)
        set_or_yell(@transformation, :crop, :fill)
      when :resize_and_pad
        set_or_yell(@transformation, :width, args[0])    
        set_or_yell(@transformation, :height, args[1])
        set_or_yell(@transformation, :background, args[2].to_s.downcase)
        set_or_yell(@transformation, :gravity, args[3].to_s.downcase)
        set_or_yell(@transformation, :crop, :pad)
      when :scale 
        set_or_yell(@transformation, :width, args[0])    
        set_or_yell(@transformation, :height, args[1])
        set_or_yell(@transformation, :crop, :scale)
      when :crop
        set_or_yell(@transformation, :width, args[0])    
        set_or_yell(@transformation, :height, args[1])
        set_or_yell(@transformation, :gravity, args[2].to_s.downcase)
        set_or_yell(@transformation, :crop, :crop)
      when :cloudinary_transformation
        args.each do
          |attr, value|        
          set_or_yell(@transformation, attr, value)
        end
      end
    end
    @transformation     
  end

  def eager
    @eager ||= self.class.processors.any?{|processor| processor[0] == :eager}
  end

  def tags
    @tags ||= self.class.processors.select{|processor| processor[0] == :tags}.map(&:last).first
  end
  
  def format
    format_processor = self.class.processors.find{|processor| processor[0] == :convert}
    if format_processor 
      # Explicit format is given
      return Array(format_processor[1]).first 
    elsif self.version_name.present? 
      # No local format. The reset should be handled by main uploader
      uploader = self.model.send(self.mounted_as)
      return uploader.format
    else
      # Try to auto-detect format
      format = Cloudinary::CarrierWave.split_format(original_filename || "").last
      return format || "png" # TODO Default format? 
    end
  end
end
