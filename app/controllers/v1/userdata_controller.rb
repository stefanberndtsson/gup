class V1::UserdataController < ApplicationController
  include PublicationsControllerHelper

  before_filter :find_current_person

  def show
    review_count = 0
    if @current_person
      review_count = publications_for_review_by_actor(person_id: @current_person.id, count_only: true)
    end
    @response[:userdata] = {
      counts: {
        review: review_count
      }
    }

    render_json
  end
end
