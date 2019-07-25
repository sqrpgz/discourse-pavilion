import { setDefaultHomepage } from "discourse/lib/utilities";

export default {
  name: 'home-edits',
  initialize(container) {
    const currentUser = container.lookup('current-user:main');
    if (!currentUser.homepage_id) setDefaultHomepage('home');
  }
};
