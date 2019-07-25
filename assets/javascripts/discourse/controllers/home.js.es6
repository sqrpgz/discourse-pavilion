import { default as computed } from 'ember-addons/ember-computed-decorators';

export default Ember.Controller.extend({
  @computed('site.categories')
  filteredCategories(categories) {
    const homeCategories = Discourse.SiteSettings.pavilion_home_categories.split('|');
    return categories.filter(c => {
      return homeCategories.indexOf(String(c.id)) > -1;
    });
  }
});
