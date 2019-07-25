import { setDefaultHomepage } from "discourse/lib/utilities";

export default {
  name: 'home-edits',
  initialize() {
    setDefaultHomepage('home');
  }
};
