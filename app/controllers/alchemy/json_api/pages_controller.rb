# frozen_string_literal: true
module Alchemy
  module JsonApi
    class PagesController < JsonApi::BaseController
      def index
        allowed = [:page_layout]

        jsonapi_filter(page_scope, allowed) do |filtered|
          jsonapi_paginate(filtered.result) do |paginated|
            render jsonapi: paginated
          end
        end
      end

      def show
        if render_fresh_page?
          @page = load_page
          render jsonapi: @page
        end
      end

      private

      def render_fresh_page?
        page = base_page_scope.find_by(id: params[:path]) ||
               base_page_scope.find_by(urlname: params[:path]) ||
               raise(ActiveRecord::RecordNotFound)
        return true unless page.cache_page?

        stale?(etag: page.cache_key + params.to_s,
               last_modified: page.published_at,
               public: !page.restricted,
               template: false)
      end

      def jsonapi_meta(pages)
        pagination = jsonapi_pagination_meta(pages)

        {
          pagination: pagination.presence,
          total: page_scope.count,
        }.compact
      end

      def load_page
        @page = load_page_by_id || load_page_by_urlname || raise(ActiveRecord::RecordNotFound)
      end

      def load_page_by_id
        page_scope.find_by(id: params[:path])
      end

      def load_page_by_urlname
        page_scope.find_by(urlname: params[:path])
      end

      def page_scope
        base_scope_with_includes.contentpages
      end

      def base_page_scope
        # cancancan is not able to merge our complex AR scopes for logged in users
        if can?(:edit_content, Page)
          Page.all
        else
          Page.published
        end
      end

      def base_scope_with_includes
        base_page_scope.
          with_language(Language.current).
          preload(language: { nodes: [:parent, :page] }, all_elements: [:parent_element, :nested_elements, { contents: { essence: :ingredient_association } }])
      end

      def jsonapi_serializer_class(_resource, _is_collection)
        ::Alchemy::JsonApi::PageSerializer
      end
    end
  end
end
