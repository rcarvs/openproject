#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

require_relative '../../support/pages/my/page'

describe 'My page', type: :feature, js: true do
  let!(:type) { FactoryBot.create :type }
  let!(:project) { FactoryBot.create :project, types: [type] }
  let!(:open_status) { FactoryBot.create :default_status }
  let!(:created_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      author: user
  end
  let!(:assigned_work_package) do
    FactoryBot.create :work_package,
                      project: project,
                      type: type,
                      assigned_to: user
  end

  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages add_work_packages save_queries])
  end
  let(:my_page) do
    Pages::My::Page.new
  end

  before do
    login_as user

    my_page.visit!
  end

  it 'renders the default view, allows altering and saving' do
    assigned_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(1)')
    created_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(2)')

    assigned_area.expect_to_exist
    created_area.expect_to_exist
    assigned_area.expect_to_span(1, 1, 2, 2)
    created_area.expect_to_span(1, 2, 2, 3)

    # The widgets load their respective contents
    expect(page)
      .to have_content(created_work_package.subject)
    expect(page)
      .to have_content(assigned_work_package.subject)

    # add widget above to right area
    my_page.add_widget(1, 1, :row, 'Calendar')

    calendar_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(3)')
    calendar_area.expect_to_span(1, 1, 2, 3)

    calendar_area.resize_to(1, 1)
    calendar_area.expect_to_span(1, 1, 2, 2)

    # add widget right next to the calendar widget
    my_page.add_widget(1, 2, :within, 'News')
    news_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(4)')
    news_area.expect_to_span(1, 2, 2, 3)

    calendar_area.resize_to(2, 1)

    sleep(0.3)

    # Resizing leads to the calender area now spanning a larger area
    calendar_area.expect_to_span(1, 1, 3, 2)
    # Because of the added row, and the resizing the other widgets (assigned and created) have moved down
    assigned_area.expect_to_span(3, 1, 4, 2)
    created_area.expect_to_span(2, 2, 3, 3)

    my_page.add_widget(1, 3, :column, 'Work packages watched by me')

    watched_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(5)')
    watched_area.expect_to_exist

    # dragging makes room for the dragged widget which means
    # that widgets that have been there are moved down
    created_area.drag_to(1, 3)

    sleep(2)

    watched_area.expect_to_span(2, 3, 3, 4)
    calendar_area.expect_to_span(1, 1, 3, 2)
    assigned_area.expect_to_span(3, 1, 4, 2)
    created_area.expect_to_span(1, 3, 2, 4)

    # Reloading keeps the user's values
    visit home_path
    my_page.visit!

    my_page.add_widget(2, 4, :column, 'Documents')
    documents_area = Components::Grids::GridArea.new('.grid--area.-widgeted:nth-of-type(6)')

    watched_area.expect_to_span(2, 3, 3, 4)
    calendar_area.expect_to_span(1, 1, 3, 2)
    assigned_area.expect_to_span(3, 1, 4, 2)
    created_area.expect_to_span(1, 3, 2, 4)
    documents_area.expect_to_span(2, 4, 3, 5)
  end
end
