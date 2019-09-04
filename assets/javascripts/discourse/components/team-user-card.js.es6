import {
  default as DiscourseURL,
  userPath,
  groupPath
} from "discourse/lib/url";

export default Ember.Component.extend({
  router: Ember.inject.service(),
  classNames: ["team-user-card"],

  actions: {
    showUser(user) {
      DiscourseURL.routeTo(userPath(user.username_lower));
    },

    showGroup(group) {
      DiscourseURL.routeTo(groupPath(group.name));
    }
  }
});