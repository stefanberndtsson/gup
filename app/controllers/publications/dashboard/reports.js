import Ember from 'ember';
import ENV from 'gup/config/environment';
import { validYear } from 'gup/lib/validations';

export default Ember.Controller.extend({
  session: Ember.inject.service('session'),
  publicationsController: Ember.inject.controller('publications'),
  publicationTypes: [],
  person: null,
  columns: {},
  filter: {},

  yearRangeDepartments: Ember.computed('filter.{start_year,end_year}', function() {
    let startYear = this.get('filter.start_year') || '';
    let endYear = this.get('filter.end_year') || '';
    let validStartYear = validYear(startYear);
    let validEndYear = validYear(endYear);
    let departments = this.get('departments');
    if (validStartYear) {
      startYear = parseInt(startYear);
      departments = departments.filter((item) => {
        if (Ember.isPresent(item.start_year)) {
          // No need to check end_year since end_year always >= start_year
          return item.start_year >= startYear;
        }
        else {
          return Ember.isBlank(item.end_year) || item.end_year >= startYear;
        }
      });
    }
    if (validEndYear) {
      endYear = parseInt(endYear);
      departments = departments.filter((item) => {
        if (Ember.isPresent(item.end_year)) {
          // No need to check start year since start_year always <= end_year
          return item.end_year <= endYear;
        }
        else {
          return Ember.isBlank(item.start_year) || item.start_year <= endYear;
        }
      });
    }
    /*
    if(validEndYear || validStartYear) {
      startYear = Ember.isPresent(startYear) ? parseInt(startYear): null;
      endYear = Ember.isPresent(endYear) ? parseInt(endYear): null;
       departments = departments.filter((item) => {
        return (
          !validStartYear || (
            Ember.isBlank(item.start_year) ||
            item.start_year >= startYear
          ) && (
            Ember.isBlank(item.end_year) ||
            item.end_year >= startYear
          )
        ) && (
          !validEndYear || (
            Ember.isBlank(item.end_year) ||
            item.end_year <= endYear
          ) && (
            Ember.isBlank(item.start_year) ||
            item.start_year =< endYear
          )
        );
      });
    }
    */
    return departments;
  }),

  selectableDepartments: Ember.computed('yearRangeDepartments', 'filter.{faculties}', function() {
    let departments = this.get('yearRangeDepartments');

    if (Ember.isPresent(this.get('filter.faculties'))) {
      let facultyId = this.get('filter.faculties');
      departments = departments.filter((item) => {
        return facultyId === item.faculty_id;
      });
    }

    if (Ember.isPresent(this.get('filter.departments'))) {
      let selectable_selected_departments = this.get('filter.departments').filter((department_id) => {
        return departments.findBy('id', department_id);
      });
      //If one or more selected department no longer among selectable, set new valid filtered selection
      if (this.get('filter.departments').length !== selectable_selected_departments.length) {
        this.set('filter.departments', selectable_selected_departments);
      }
    }
    return departments;
  }),

  selectableFaculties: Ember.computed('yearRangeDepartments', 'publicationsController.faculties', function() {
    // TODO: this could be computed prop for increased performance
    let facultyIds = this.get('yearRangeDepartments').reduce((result, department) => {
        result[department.faculty_id] = department.faculty_id;
        return result;
      }, []);
    let faculties = this.get('publicationsController.faculties');
    console.dir(faculties);
    return facultyIds.map(function(id) {
      //TODO: this could be made much faster by indexing faculties by id instead
      return faculties.findBy('id', id) || Ember.Object.create({
        id: id,
        name: 'Unknown/Extern (id: ' + id + ')'
      });
    }); //.compact()?
  }),

  columnArray: Ember.computed('columns.{year,faculty,department,publication_type,ref_value}', function() {
    var cArray = [];
    if(this.get('columns.year')) { cArray.push('year'); }
    if(this.get('columns.faculty')) { cArray.push('faculty_id'); }
    if(this.get('columns.department')) { cArray.push('department_id'); }
    if(this.get('columns.publication_type')) { cArray.push('publication_type_id'); }
    if(this.get('columns.ref_value')) { cArray.push('ref_value'); }
    return cArray;
  }),
  filterData: Ember.computed('filter.{start_year,end_year,faculties,departments,publication_types,ref_value}','publicationTypes.@each.checked', 'person.identifiers', function() {
    var that = this;

    var publication_types = [];
    this.get('publicationTypes').forEach(function(item) {
      if(item.checked) {
        publication_types.push(item.code);
      }
    });
    this.set('filter.publication_types', publication_types);
    if(this.get('person.identifiers')) {
      this.get('person.identifiers').forEach(function(identifier) {
        that.set('filter.persons', [identifier.value]);
      });
    }

    return this.get('filter');
  }),

  csvUrl: Ember.computed('columnArray', 'filterData', function() {
    var that = this;
    var date = moment();
    var report_name = "report-"+date.format("YYYY-MM-DD_HHMM");
    var token =  this.get("session.data.authenticated.token");
    var report_data = Ember.$.param({
      report: {
        filter: that.get('filterData'),
        columns: that.get('columnArray')
      }
    });
    return ENV.APP.serviceURL + '/reports/' + report_name + '?token=' + token + '&' + report_data;
  }),

  model: {},
});
