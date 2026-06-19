import Route from '@ember/routing/route';

export default class PaymentRoute extends Route {
  model(params) {
    return { reference: params.reference };
  }
}
