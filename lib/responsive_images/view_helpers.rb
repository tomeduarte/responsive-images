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

      image_src, data_sizes = setup(image, options)

      # Return the image tag with our responsive data attributes
      return image_tag image_src, data_sizes
    end
    
    
    def responsive_background_image image = nil, options={}
      # is it worth to process?
      return if image == nil

      image_src, data_sizes = setup(image, options)

      data_hash = { style: "background-image: url(#{image_src})" }.merge(data_sizes)
    end
  
    
    private

    def setup image, options
      # Merge any options passed with the configured options
      sizes = ResponsiveImages.options.deep_merge(options)

      # Let's create a hash of the alternative options for our data attributes
      data_sizes = alternative_sizes(image, sizes).merge(options)

      # image url
      image_src = src_path(image, sizes)

      # if lazy load is enabled for the gem
      if ResponsiveImages.options[:lazy_load]
        # do we have classes for this image?
        if options[:class]
          # check if this image is to be lazy loaded
          lazy_load = options[:class].split(' ').include? 'lazy'

          if lazy_load
            data_sizes['data-original'] = image_src
            image_src = ResponsiveImages.options[:lazy_load_default] ? ResponsiveImages.options[:lazy_load_default] : ''
          end
        end
      end

      return image_src, data_sizes
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
          image_src = sizes[:sizes][identifiers[:tablet]].present? ? image.url(sizes[:sizes][identifiers[:tablet]]) : image.url(sizes[:default])
        when :mobile
          image_src = sizes[:sizes][identifiers[:mobile]].present? ? image.url(sizes[:sizes][identifiers[:mobile]]) : image.url(sizes[:default])
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

      # generate URLs for each device
      %w(desktop tablet mobile).each do |device|
        key = "data-#{device}-src"
        data_sizes[key] = image.url sizes[:sizes][identifiers[device.to_sym]]
      end

      data_sizes
    end

    # detect authorized modifiers and return appropriate identifiers
    # for desktop, tablet and mobile
    def detect_device_identifiers options

      quality_identifier = ResponsiveImages.options[:quality].nil? ? '' : "-#{ResponsiveImages.options[:quality]}"
      identifiers = {
        :desktop => "desktop" + quality_identifier,
        :tablet  => "tablet" + quality_identifier,
        :mobile  => "mobile" + quality_identifier
      }

      if options[:class]
        if ResponsiveImages.options[:authorized_modifiers].nil?
          modifiers = [ ]
        else
          modifiers = options[:class].split(' ').select { |css_class| ResponsiveImages.options[:authorized_modifiers].include?(css_class) }
        end

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
