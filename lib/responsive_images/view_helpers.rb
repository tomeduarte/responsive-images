module ResponsiveImages
  module ViewHelpers

    
    # Use mobvious to get the user's device type, it will return mobile, tablet or desktop
    def device_type
      return request.env['mobvious.device_type']
    end
    
    
    # Create a image tag with our responsive image data attributes
    def responsive_image_tag image = nil, options={}
      # is it worth to process?
      return if image == nil

      # Merge any options passed with the configured options
      sizes = ResponsiveImages.options.deep_merge(options)  
      # Let's create a hash of the alternative options for our data attributes    
      data_sizes = alternative_sizes(image, sizes)
      # Get the image source
      image_src = src_path(image, sizes)      
      # Return the image tag with our responsive data attributes
      return image_tag image_src, data_sizes.merge(options)
    end
    
    
    def responsive_background_image image = nil, options={}
      # is it worth to process?
      return if image == nil

      # Merge any options passed with the configured options
      sizes = ResponsiveImages.options.deep_merge(options)
      data_hash = { style: "background-image: url(#{src_path(image, sizes)})" }.merge(alternative_sizes(image, sizes)).merge(options)
    end
  
    
    # Let's identify the default image size for the image tag. If it's a desktop then our
    # default src attribute should be desktop (or default) but if it's a mobile or table
    # then we should set the src attribute to the mobile or tablet image
    def src_path image, sizes

      # get device type identifiers
      identifiers = detect_device_identifiers(sizes)

      begin
        case device_type
        when :desktop
          image_src = sizes[:default] == :default ? image.url : image.url(sizes[:sizes][identifiers[:desktop]])
        when :tablet
          image_src = sizes[:sizes][tablet_identifier].present? ? image.url(sizes[:sizes][identifiers[:tablet]]) : image.url(sizes[:default])
        when :mobile
          image_src = sizes[:sizes][mobile_identifier].present? ? image.url(sizes[:sizes][identifiers[:mobile]]) : image.url(sizes[:default])
        end
      rescue ArgumentError # unexistent version
        image_src = sizes[:default] == :default ? image.url : image.url(:default)
      end
    end
    
    
    # Loop over the images sizes and create our data attributes hash
    def alternative_sizes image, sizes
      data_sizes = {}

      # get device type identifiers
      identifiers = detect_device_identifiers(sizes)

      # update version accordingly
      sizes[:sizes].each do |size, value|
        if value.present?
          case size
          when :default
            version = sizes[:sizes][identifiers[:desktop]]
          when :desktop
            version = sizes[:sizes][identifiers[:desktop]]
          when :tablet
            version = sizes[:sizes][identifiers[:tablet]]
          when :mobile
            version = sizes[:sizes][identifiers[:mobile]]
          else
            version = value
          end

          begin
            key = "data-#{size}-src"

            # add it only if the file exists
            if version == :default
              data_sizes[key] = image.url
            else
              # add only if it's an existent version
              data_sizes[key] = image.url(version) # if image.send(version).file.exists?
            end
          rescue ArgumentError # unexistent version
          end
        else
          false
        end
      end
      data_sizes
    end

    # detect authorized modifiers and return appropriate identifiers
    # for desktop, tablet and mobile
    def detect_device_identifiers options

      identifiers = {
        :desktop => :desktop,
        :tablet  => :tablet,
        :mobile  => :mobile
      }

      if options[:class]
        modifiers = options[:class].split(' ').select { |css_class| ResponsiveImages.options[:authorized_modifiers].include?(css_class) }

        unless modifiers.empty?
          identifiers[:desktop]  = (modifiers.first + "-" + identifiers[:desktop].to_s).to_sym
          identifiers[:tablet]   = (modifiers.first + "-" + identifiers[:tablet].to_s).to_sym
          identifiers[:mobile]   = (modifiers.first + "-" + identifiers[:mobile].to_s).to_sym
        end
      end

      identifiers
    end

  end  
end
