import EmberRouter from '@embroider/router';
import config from 'frontend/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('login');
  this.route('gallery');
  this.route('amenities');
  this.route('booking');
  this.route('enquiry');
  this.route('track');
  this.route('contact');
  this.route('admin');
  this.route('payment', { path: '/payment/:reference' });
  this.route('invoice', { path: '/invoice/:reference' });
  this.route('receipt', { path: '/receipt/:reference' });
});
