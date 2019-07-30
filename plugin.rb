# name: discourse-pavilion
# about: Pavilion customisations
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-pavilion

register_asset "stylesheets/common/pavilion.scss"
register_asset "stylesheets/mobile/pavilion.scss", :mobile

after_initialize do
  module ::PavilionHome
    class Engine < ::Rails::Engine
      engine_name "pavilion_home"
      isolate_namespace PavilionHome
    end
  end
  
  require 'homepage_constraint'
  Discourse::Application.routes.prepend do
    root to: "pavilion_home/page#index", constraints: HomePageConstraint.new("home")
    get "/home" => "pavilion_home/page#index"
  end
  
  require_dependency 'application_controller'
  class PavilionHome::PageController < ApplicationController    
    def index
      json = {
        members: ActiveModel::ArraySerializer.new(
          Group.find_by(name: 'team').users,
          each_serializer: BasicUserSerializer
        )
      }
      
      if (current_user && (home_category = current_user.home_category))
        topic_list = TopicQuery.new(current_user,
          category: home_category.id,
          per_page: 6
        ).list_latest
        json[:topic_list] = TopicListSerializer.new(topic_list, scope: Guardian.new(current_user)).as_json
      end
      
      render_json_dump(json)
    end
  end
  
  add_to_serializer(:group_user, :bio) { object.user_profile.bio_processed }
  add_to_serializer(:current_user, :homepage_id) { object.user_option.homepage_id }
  
  module UserOptionExtension
    def homepage
      if homepage_id == 101
        "home"
      else
        super
      end
    end
  end
  
  require_dependency 'user_option'
  class ::UserOption
    prepend UserOptionExtension
  end
  
  Group.register_custom_field_type('client_group', :boolean)
  Group.preloaded_custom_fields << "client_group" if Group.respond_to? :preloaded_custom_fields
  
  module ClientGroupModelExtension
    def expire_cache
      super
      @featured_groups = nil
    end
  end
  
  require_dependency 'group'
  class ::Group
    prepend ClientGroupModelExtension

    def client_group
      if custom_fields['client_group'] != nil
        custom_fields['client_group']
      else
        false
      end
    end
    
    def self.client_groups
      @client_groups ||= begin
        Group.where("groups.id in (
          SELECT group_id FROM group_custom_fields
          WHERE name = 'client_group' AND
          value::boolean IS TRUE
        )")
      end
    end
  end
  
  require_dependency 'category'
  class ::Category
    def self.client_group_category(group_id)
      Category.where("categories.id in (
        SELECT category_id FROM category_groups
        WHERE group_id = #{group_id}
        AND permission_type = 1
      )").first
    end
  end
  
  module FeatureGroupUserExtension
    def reload
      @client_groups = nil
      super
    end
  end
  
  require_dependency 'user'
  class ::User
    prepend FeatureGroupUserExtension

    def home_category
      if client_groups.present?
        Category.client_group_category(client_groups.pluck(:id).first)
      end
    end
    
    def client_groups
      Group.member_of(Group.client_groups, self)
    end
  end
  
  module AdminGroupsControllerExtension
    private def group_params
      client_group = params.require(:group).permit(:client_group)[:client_group]

      if client_group != nil
        merge_params = {
          custom_fields: { client_group: client_group }
        }
        super.merge(merge_params)
      else
        super
      end
    end
  end

  module GroupsControllerExtension
    private def group_params(automatic: false)
      client_group = params.require(:group).permit(:client_group)[:client_group]

      if client_group != nil
        merge_params = {
          custom_fields: { client_group: client_group }
        }
        super.merge(merge_params)
      else
        super
      end
    end
  end

  require_dependency 'admin/groups_controller'
  class ::Admin::GroupsController
    prepend AdminGroupsControllerExtension
  end

  require_dependency 'groups_controller'
  class ::GroupsController
    prepend GroupsControllerExtension
  end
  
  add_to_serializer(:basic_group, :client_group) { object.client_group }
end
