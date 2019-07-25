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

  Discourse::Application.routes.append do
    get "/home" => "pavilion_home/page#index"
  end

  class PavilionHome::PageController < ::ApplicationController
    def index
      render nothing: true
    end
  end
  
  add_to_serializer(:group_user, :bio) { object.user_profile.bio_processed }
end
