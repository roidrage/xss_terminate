module XssTerminate
  def self.included(base)
    base.extend(ClassMethods)
    # sets up default of stripping tags for all fields
    base.send(:xss_terminate)
  end

  module ClassMethods
    def xss_terminate(options = {})
      if options.equal?(:none)
        write_inheritable_attribute(:xss_terminate_options, nil)
      else
        before_validation :sanitize_fields

        sanitize_options = {}
        sanitize_options[:tags] = options[:tags] if options[:tags]
        sanitize_options[:attributes] = options[:attributes] if options[:attributes]

        write_inheritable_attribute(:xss_terminate_options, {
          :except => (options[:except] || []),
          :html5lib_sanitize => (options[:html5lib_sanitize] || []),
          :sanitize => (options[:sanitize] || []),
          :sanitize_options => sanitize_options
        })
      
        class_inheritable_reader :xss_terminate_options
      
        include XssTerminate::InstanceMethods
      end
    end
  end
  
  module InstanceMethods

    def sanitize_fields
      # fix a bug with Rails internal AR::Base models that get loaded before
      # the plugin, like CGI::Sessions::ActiveRecordStore::Session
      return if xss_terminate_options.nil?
      
      self.class.columns.each do |column|
        next unless (column.type == :string || column.type == :text)
        
        field = column.name.to_sym
        value = self[field]

        next if value.nil?
        
        if xss_terminate_options[:except].include?(field)
          next
        elsif xss_terminate_options[:html5lib_sanitize].include?(field)
          self[field] = HTML5libSanitize.new.sanitize_html(value)
        elsif xss_terminate_options[:sanitize].include?(field)
          self[field] = RailsSanitize.white_list_sanitizer.sanitize(value, xss_terminate_options[:sanitize_options])
        else
          self[field] = RailsSanitize.full_sanitizer.sanitize(value)
        end
      end
      
    end
  end
end
