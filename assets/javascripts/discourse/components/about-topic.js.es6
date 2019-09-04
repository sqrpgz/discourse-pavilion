import DiscourseURL from 'discourse/lib/url';
import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Component.extend({
  classNames: 'about-topic',

  @computed('topic.posters')
  displayUser(posters) {
    return posters[0].user;
  },

  click() {
    DiscourseURL.routeTo(this.get('topic.url'));
  }
});