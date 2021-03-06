# frozen_string_literal: true

module Alchemy
  module JsonApi
    class PagesController < JsonApi::BaseController
      before_action :load_page, only: :show

      def index
        allowed = [:page_layout]

        jsonapi_filter(page_scope, allowed) do |filtered|
          jsonapi_paginate(filtered.result) do |paginated|
            render jsonapi: paginated
          end
        end
      end

      def show
        render jsonapi: @page
      end

      private

      def jsonapi_meta(pages)
        pagination = jsonapi_pagination_meta(pages)

        {
          pagination: pagination.presence,
          total: page_scope.count
        }.compact
      end

      def load_page
        @page = load_page_by_id || load_page_by_urlname || raise(ActiveRecord::RecordNotFound)
      end

      def load_page_by_id
        return unless params[:path] =~ /\A\d+\z/
        page_scope.find_by(id: params[:path])
      end

      def load_page_by_urlname
        page_scope.find_by(urlname: params[:path])
      end

      def page_scope
        page_scope_with_includes.contentpages
      end

      def page_scope_with_includes
        base_page_scope.
          with_language(Language.current).
          preload(language: { nodes: [:parent, :page, :children] }, all_elements: { contents: { essence: :ingredient_association } })
      end

      def base_page_scope
        # cancancan is not able to merge our complex AR scopes for logged in users
        if can?(:edit_content, ::Alchemy::Page)
          ::Alchemy::JsonApi::Page.all
        else
          ::Alchemy::JsonApi::Page.published
        end
      end

      def jsonapi_serializer_class(_resource, _is_collection)
        ::Alchemy::JsonApi::PageSerializer
      end
    end
  end
end
