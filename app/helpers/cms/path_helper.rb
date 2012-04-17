module Cms

  # @todo All methods really need to be renamed to match conventions for Engines.
  # In CMS::Engine, shouldn't have cms_ in method name.
  # From app, should be cms.xyz_path
  module PathHelper

    # Returns the relative path to the given attachment.
    # Content editors will see exact specific version path, while other users will see the 'public' url for the path.
    def attachment_path_for(attachment)
      if current_user.able_to?(:edit_content)
        attachment.attachment_version_path
      else
        attachment.data_file_path
      end
    end

    def cms_index_path_for(resource, options={})
      polymorphic_path(build_path_for(resource), options)
    end

    # @deprecated Remove all usages of this in favor of cms_index_path_for ()
    def cms_index_url_for(resource, options={})
      send("#{resource_collection_name(resource).underscore.pluralize.gsub('/', '_')}_url", options)
    end

    def cms_new_path_for(resource, options={})
      new_polymorphic_path(build_path_for(resource), options)
    end

    # @deprecated Remove all usages of this in favor of cms_new_path_for ()
    def cms_new_url_for(resource, options={})
      send("new_#{resource_collection_name(resource).underscore.gsub('/', '_')}_url", options)
    end

    def cms_connectable_path(connectable, options={})
      if Portlet === connectable
        cms.portlet_path(connectable)
      else
        connectable
      end
    end

    # @todo Really needs to be renamed to match conventions for Engines.
    # In CMS::Engine, should be edit_connectable_path
    # From app, should be cms.edit_connectable_path
    def edit_cms_connectable_path(connectable, options={})
      if Portlet === connectable
        edit_portlet_path(connectable, options)
      else
        polymorphic_path([:edit, connectable], options)
      end
    end

    # Returns the Engine Proxy that this resource is from.
    def engine_for(resource)
      EngineHelper.decorate(resource)
      send(resource.engine_name)
    end

    def path_elements_for(resource)
      EngineHelper.decorate(resource)
      resource.path_elements
    end

    private

    def build_path_for(model_or_class_or_content_type)
      path = []
      path << engine_for(model_or_class_or_content_type)
      path.concat path_elements_for(model_or_class_or_content_type)
      path
    end

    # Returns the name of the collection that this resource belongs to
    # the resource can be a ContentType, ActiveRecord::Base instance
    # or just a string or symbol
    def resource_collection_name(resource)
      if resource.respond_to?(:resource_collection_name)
        return resource.resource_collection_name
      end
      case resource
        when ContentType then
          resource.route_name
        when ActiveRecord::Base then
          resource.class.model_name.demodulize
        else
          resource.to_s
      end
    end

  end
end
