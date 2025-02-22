#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

require_relative '../support/pages/meetings/index'

RSpec.describe 'Meetings', 'Index', :with_cuprite do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %w[meetings]) }
  let(:role) { create(:role, permissions:) }
  let(:permissions) { %i(view_meetings) }
  let(:user) do
    create(:user) do |user|
      [project, other_project].each do |p|
        create(:member,
               project: p,
               principal: user,
               roles: [role])
      end
    end
  end

  let(:meeting) do
    create(:meeting, project:, title: 'Awesome meeting today!', start_time: Time.current)
  end
  let(:tomorrows_meeting) do
    create(:meeting, project:, title: 'Awesome meeting tomorrow!', start_time: 1.day.from_now)
  end
  let(:yesterdays_meeting) do
    create(:meeting, project:, title: 'Awesome meeting yesterday!', start_time: 1.day.ago)
  end

  shared_let(:other_project_meeting) do
    create(:meeting, project: other_project, title: 'Awesome other project meeting!', start_time: 2.days.from_now)
  end

  def setup_meeting_involvement
    create(:meeting_participant, :invitee,  user:, meeting: tomorrows_meeting)
    create(:meeting_participant, :invitee,  user:, meeting: yesterdays_meeting)
    create(:meeting_participant, :attendee, user:, meeting:)
    meeting.update!(author: user)
  end

  before do
    login_as user
  end

  shared_examples 'sidebar filtering' do |context:|
    context 'when filtering with the sidebar' do
      shared_let(:ongoing_meeting) do
        create(:meeting, project:, title: 'Awesome ongoing meeting!', start_time: 30.minutes.ago)
      end

      before do
        setup_meeting_involvement
        meetings_page.visit!
      end

      context 'with the "Upcoming meetings" filter' do
        before do
          meetings_page.set_sidebar_filter 'Upcoming meetings'
        end

        it 'shows all upcoming and ongoing meetings', :aggregate_failures do
          expected_upcoming_meetings = if context == :global
                                         [ongoing_meeting, meeting, tomorrows_meeting, other_project_meeting]
                                       else
                                         [ongoing_meeting, meeting, tomorrows_meeting]
                                       end

          meetings_page.expect_meetings_listed_in_order(*expected_upcoming_meetings)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting)
        end
      end

      context 'with the "Past meetings" filter' do
        before do
          meetings_page.set_sidebar_filter 'Past meetings'
        end

        it 'show all past and ongoing meetings' do
          meetings_page.expect_meetings_listed_in_order(ongoing_meeting,
                                                        yesterdays_meeting)
          meetings_page.expect_meetings_not_listed(meeting,
                                                   tomorrows_meeting)
        end
      end

      context 'with the "Upcoming invitations" filter' do
        before do
          meetings_page.set_sidebar_filter 'Upcoming invitations'
        end

        it "shows all upcoming meetings I've been marked as invited to" do
          meetings_page.expect_meetings_listed(tomorrows_meeting)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting,
                                                   meeting,
                                                   ongoing_meeting)
        end
      end

      context 'with the "Past invitations" filter' do
        before do
          meetings_page.set_sidebar_filter 'Past invitations'
        end

        it "shows all past meetings I've been marked as invited to" do
          meetings_page.expect_meetings_listed(yesterdays_meeting)
          meetings_page.expect_meetings_not_listed(ongoing_meeting,
                                                   meeting,
                                                   tomorrows_meeting)
        end
      end

      context 'with the "Attendee" filter' do
        before do
          meetings_page.set_sidebar_filter 'Attendee'
        end

        it "shows all meetings I've been marked as attending to" do
          meetings_page.expect_meetings_listed(meeting)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting,
                                                   ongoing_meeting,
                                                   tomorrows_meeting)
        end
      end

      context 'with the "Creator" filter' do
        before do
          meetings_page.set_sidebar_filter 'Creator'
        end

        it "shows all meetings I'm the author of" do
          meetings_page.expect_meetings_listed(meeting)
          meetings_page.expect_meetings_not_listed(yesterdays_meeting,
                                                   ongoing_meeting,
                                                   tomorrows_meeting)
        end
      end
    end
  end

  context 'when visiting from a global context', with_flag: { more_global_index_pages: true } do
    let(:meetings_page) { Pages::Meetings::Index.new(project: nil) }

    it 'lists all upcoming meetings for all projects the user has access to' do
      meeting
      yesterdays_meeting

      meetings_page.navigate_by_modules_menu
      meetings_page.expect_meetings_listed(meeting, other_project_meeting)
      meetings_page.expect_meetings_not_listed(yesterdays_meeting)
    end

    context 'and the user is allowed to create meetings' do
      let(:permissions) { %i(view_meetings create_meetings) }

      it 'shows the create new buttons' do
        meetings_page.navigate_by_modules_menu

        meetings_page.expect_create_new_buttons
      end
    end

    context 'and the user is not allowed to create meetings' do
      let(:permissions) { %i[view_meetings] }

      it "doesn't show a create new button" do
        meetings_page.navigate_by_modules_menu

        meetings_page.expect_no_create_new_buttons
      end
    end

    include_examples 'sidebar filtering', context: :global
  end

  context 'when visiting from a project specific context' do
    let(:meetings_page) { Pages::Meetings::Index.new(project:) }

    context 'via the menu' do
      specify 'with no meetings' do
        meetings_page.navigate_by_project_menu

        meetings_page.expect_no_meetings_listed
      end
    end

    context 'when the user is allowed to create meetings' do
      let(:permissions) { %i(view_meetings create_meetings) }

      it 'shows the create new buttons' do
        meetings_page.visit!
        meetings_page.expect_create_new_buttons
      end
    end

    context 'when the user is not allowed to create meetings' do
      let(:permissions) { %i[view_meetings] }

      it "doesn't show the create new buttons" do
        meetings_page.visit!
        meetings_page.expect_no_create_new_buttons
      end
    end

    include_examples 'sidebar filtering', context: :project

    specify 'with 1 meeting listed' do
      meeting
      meetings_page.visit!

      meetings_page.expect_meetings_listed(meeting)
    end

    it 'with pagination', with_settings: { per_page_options: '1' } do
      meeting
      tomorrows_meeting
      yesterdays_meeting

      # First page displays the soonest occurring upcoming meeting
      meetings_page.visit!
      meetings_page.expect_meetings_listed(meeting)
      meetings_page.expect_meetings_not_listed(yesterdays_meeting, # Past meetings not displayed
                                               tomorrows_meeting)

      meetings_page.expect_to_be_on_page(1)

      # Second page shows the next occurring upcoming meeting
      meetings_page.to_page(2)
      meetings_page.expect_meetings_listed(tomorrows_meeting)
      meetings_page.expect_meetings_not_listed(yesterdays_meeting, # Past meetings not displayed
                                               meeting)
    end
  end
end
