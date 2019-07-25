# name: discourse-pavilion
# about: Pavilion customisations
# version: 0.1
# authors: Angus McLeod
# url: https://github.com/angusmcleod/discourse-pavilion

after_initialize do
  add_to_serializer(:group_user, :bio) { object.user_profile.bio_processed }
end