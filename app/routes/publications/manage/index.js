import Ember from 'ember';

export default Ember.Route.extend({
  actions:{
    create: function() {
      var that = this;
      var successHandler = function(model) {
        var rsvp =  Ember.RSVP.hash({drafts: that.store.find("draft"), publications: that.store.find("publication")});
        rsvp.then(function(lists) {
          that.controllerFor('publications.manage').set('drafts',lists.drafts);
          that.controllerFor('publications.manage').set('publications',lists.publications);
          // här väljer man att gå till den första posten om listan är icke-tom
          that.transitionTo('publications.manage.show.edit', model.pubid);
        });        
      };
      var errorHandler = function(reason) {
        console.log(reason);
        that.controller.set('hasErrors', true);
        that.controller.set('showErrorHeader', true);
        that.controller.set('errors', reason.responseJSON.errors);
        return false;
      };
      this.store.save('publication', {}, {"datasource": 'none'}).then(successHandler, errorHandler);
    },

    import: function(sourceData){
      console.log(sourceData);
      var that = this;
      var successHandler = function(model) {
        var rsvp =  Ember.RSVP.hash({drafts: that.store.find("draft"), publications: that.store.find("publication")});
        rsvp.then(function(lists) {
          that.controllerFor('publications.manage').set('drafts',lists.drafts);
          that.controllerFor('publications.manage').set('publications',lists.publications);
          // här ska man kunna välja att gå till den första posten om listan är icke-tom
          that.transitionTo('publications.manage.show.edit', model.pubid);
        });        
      };
      var errorHandler = function(reason) {
        console.log(reason);
        that.controller.set('hasErrors', true);
        that.controller.set('showErrorHeader', true);
        that.controller.set('errors', reason.responseJSON.errors);
        return false;
      };
      this.store.save('publication', {}, {"datasource": sourceData.selectedSource, "sourceid": sourceData.sourceId}).then(successHandler, errorHandler);    
    }
  }
});
