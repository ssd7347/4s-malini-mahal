import Route from '@ember/routing/route';

export default class ReceiptRoute extends Route {
  model(params) {
    return { reference: params.reference };
  }
}
