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

RSpec.describe 'Boards routing' do
  it do
    expect(subject)
      .to route(:get, '/boards/all')
            .to(controller: 'boards/boards', action: 'overview')
  end

  it do
    expect(subject)
      .to route(:get, '/boards')
            .to(controller: 'boards/boards', action: 'index')
  end

  it do
    expect(subject)
      .to route(:get, '/boards/1')
            .to(controller: 'boards/boards', action: 'show', id: 1)
  end

  it do
    expect(subject)
      .to route(:get, '/projects/foobar/boards/1')
            .to(controller: 'boards/boards', action: 'show', project_id: 'foobar', id: 1)
  end

  it do
    expect(subject)
      .to route(:get, '/boards/new')
            .to(controller: 'boards/boards', action: 'new')
  end

  it do
    expect(subject)
      .to route(:get, '/projects/foobar/boards/new')
            .to(controller: 'boards/boards', action: 'new', project_id: 'foobar')
  end

  it do
    expect(subject)
      .to route(:post, '/projects/foobar/boards')
            .to(controller: 'boards/boards', action: 'create', project_id: 'foobar')
  end

  it do
    expect(subject)
      .to route(:post, '/boards')
            .to(controller: 'boards/boards', action: 'create')
  end
end
