import Ember from 'ember';
import ApplicationRouteMixin from 'simple-auth/mixins/application-route-mixin';

export default Ember.Route.extend(ApplicationRouteMixin, {

	beforeModel: function() {
		this._super();
	//	this.transitionTo('login');
		if (this.get("session.authenticated")) {
			//console.log("session", this.get("session"));
			this.transitionTo('publications.manage');
		}
		else {
			this.transitionTo('login');
		}
	},
	model: function() {
		return Ember.RSVP.hash({

		});
	},
	setupController: function(controller, models) {


	},
	actions: {
		sessionAuthenticationSucceeded: function() {
			this.transitionTo("publications.manage");
	    //	return this._super();	
	    },
		sessionAuthenticationFailed: function(error) {
		    this.controllerFor('login').set('error', error);
		},
	}
});