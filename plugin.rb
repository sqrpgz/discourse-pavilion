# name: discourse-pavilion
# about: Pavilion customisations
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-pavilion

register_asset "stylesheets/common/pavilion.scss"
register_asset "stylesheets/mobile/pavilion.scss", :mobile

Discourse.filters.push(:work)
Discourse.anonymous_filters.push(:work)

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
  
  class HomepageUserSerializer < BasicUserSerializer
    attributes :title,
               :bio
    
    def bio
      object.user_profile.bio_processed
    end
  end
  
  require_dependency 'topic_query'
  class ::TopicQuery
    def list_work
      @options[:assigned] = @user.username
      create_list(:work) do |result|
        result.where("topics.id NOT IN (
          SELECT topic_id FROM topic_tags
          WHERE topic_tags.tag_id in (
            SELECT id FROM tags
            WHERE tags.name = 'done'
          )
        )")
      end
    end
  end
  
  require_dependency 'topic_list_item_serializer'
  class HomeTopicListItemSerializer < TopicListItemSerializer
    def excerpt
      doc = Nokogiri::HTML::fragment(object.first_post.cooked)
      doc.search('.//img').remove
      PrettyText.excerpt(doc.to_html, 300, keep_emoji_images: true)
    end

    def include_excerpt?
      true
    end
  end
  
  require_dependency 'topic_list_serializer'
  class HomeTopicListSerializer < TopicListSerializer
    has_many :topics, serializer: HomeTopicListItemSerializer, embed: :objects
  end
  
  require_dependency 'application_controller'
  require_dependency 'user_serializer'
  class PavilionHome::PageController < ApplicationController    
    def index
      json = {}
      guardian = Guardian.new(current_user)
      
      if team_group = Group.find_by(name: SiteSetting.pavilion_team_group)
        json[:members] = ActiveModel::ArraySerializer.new(
          team_group.users.sample(2),
          each_serializer: UserSerializer,
          scope: guardian
        )
      end
      
      topic_list = nil
      
      if current_user && current_user.staff?
        topic_list = TopicQuery.new(current_user, per_page: 6).list_work
      elsif (current_user && (home_category = current_user.home_category))
        topic_list = TopicQuery.new(current_user,
          category: home_category.id,
          per_page: 6
        ).list_latest
      end
      
      if topic_list
        json[:topic_list] = TopicListSerializer.new(topic_list,
          scope: guardian
        ).as_json
      end
        
      if about_category = Category.find_by(name: 'About')
        if about_topic_list = TopicQuery.new(current_user,
            per_page: 3,
            category: about_category.id,
            no_definitions: true
          ).list_latest
          json[:about_topic_list] = HomeTopicListSerializer.new(about_topic_list,
            scope: guardian
          ).as_json
        end
      end
      
      render_json_dump(json)
    end
  end
  
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
      @client_groups = nil
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
