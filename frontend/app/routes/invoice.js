import Route from '@ember/routing/route';

export default class InvoiceRoute extends Route {
  model(params) {
    return { reference: params.reference };
  }
}
