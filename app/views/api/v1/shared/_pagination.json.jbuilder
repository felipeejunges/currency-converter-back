# frozen_string_literal: true

if @pagination.present?
  json.pagination do
    json.extract! @pagination, :page, :prev, :next, :count, :limit, :pages, :last, :from, :to, :vars, :series
  end
end
