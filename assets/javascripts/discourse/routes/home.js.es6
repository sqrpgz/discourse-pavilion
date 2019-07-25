import { ajax } from 'discourse/lib/ajax';

export default Discourse.Route.extend({
  model() {
    return ajax(`/groups/team/members.json`);
  },

  setupController(controller, model) {
    controller.set('teamMembers', model.members);
  }
});
