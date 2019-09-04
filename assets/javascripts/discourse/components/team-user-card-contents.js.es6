import UserCardContents from 'discourse/components/user-card-contents';

export default UserCardContents.extend({
  elementId: null,
  layoutName: 'components/user-card-contents',
  visible: true,
  username: Ember.computed.alias('user.username'),

  didInsertElement() {
  },

  keyUp() {
  },

  cleanUp() {
  },
});