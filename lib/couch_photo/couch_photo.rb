module CouchPhoto
  def self.included(base)
    base.extend ClassMethods
  end

  def original(filepath, blob=nil)
    self["_id"] = File.basename filepath if self.class.override_id?
    blob ||= File.read filepath
    image_format = filepath.match(/^.*\.([^\.]*)$/)[1]
    attachment_name = "original.#{image_format}"
    attachment = {:name => attachment_name, :file => Attachment.new(blob, attachment_name)}
    update_or_create_attachment attachment
    self.class.variation_definitions.run_variations(blob).each do |variation_name, variation_blob|
      update_or_create_attachment :name => "variations/#{variation_name}.#{image_format}", :file => Attachment.new(variation_blob, attachment_name) 
    end
  end
  
  def update_or_create_attachment(attachment)
    if self.has_attachment? attachment[:name]
      self.update_attachment attachment
    else
      self.create_attachment attachment
    end
  end

  module ClassMethods
    def variations(&block)
      raise "You must pass a block to the `variations' method." unless block
      variation_definitions.instance_eval(&block)
    end

    def variation_definitions
      @variation_definitions ||= Variations.new
    end
    
    def override_id!
      @override_id = true
    end

    def override_id?
      @override_id
    end
  end
end