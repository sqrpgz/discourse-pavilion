import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  @computed('site.categories')
  filteredCategories(categories) {
    const homeCategories = ['welcome', 'clients', 'plugins'];
    return categories.filter(c => {
      return homeCategories.indexOf(c.slug) > -1;
    });
  }
});
