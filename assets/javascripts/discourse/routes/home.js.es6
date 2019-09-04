import { ajax } from 'discourse/lib/ajax';
import TopicList from "discourse/models/topic-list";

export default Discourse.Route.extend({
  model() {
    return ajax(`/home`);
  },

  setupController(controller, model) {
    let props = {};

    if (model) {
      if (model.teamMembers) {
        props['teamMembers'] = model.members;
      };

      if (model.topic_list) {
        props['topics'] = TopicList.topicsFrom(this.store, model.topic_list);

        if (props['topics'].length) {
          props['category'] = props['topics'][0].category;
        };
      }
    }

    controller.setProperties(props);
  }
});
