# frozen_string_literal: true
require "alchemy/json_api/essence_serializer"

module Alchemy
  module JsonApi
    class EssencePictureSerializer < BaseSerializer
      include EssenceSerializer

      attributes(
        :title,
        :caption,
        :link_title,
        :link_target,
      )
      attribute :ingredient, &:picture_url
      attribute :alt_text, &:alt_tag
      attribute :link_url, &:link

      with_options if: proc { |essence| essence.picture.present? } do
        attribute :image_dimensions do |essence|
          sizes = essence.content.settings[:size]&.split("x", 2)&.map(&:to_i) || [
            essence.image_file_width,
            essence.image_file_height,
          ]

          ratio = essence.image_file_width.to_f / essence.image_file_height
          width = sizes[0].zero? ? sizes[1] * ratio : sizes[0]
          height = sizes[1].zero? ? sizes[0] / ratio : sizes[1]

          {
            width: width,
            height: height,
          }
        end

        attribute :srcset do |essence|
          essence.content.settings.fetch(:srcset, []).map do |src|
            case src
            when Hash
              url = essence.picture_url(src)
              size = src[:size]
              type = Mime::Type.lookup_by_extension(src[:format] || essence.picture.default_render_format)
            else
              url = essence.picture_url(size: src)
              size = src
              type = Mime::Type.lookup_by_extension(essence.picture.default_render_format)
            end
            width, height = size.split("x", 2)

            {
              url: url,
              desc: "#{width}w",
              width: width,
              height: height,
              type: type.to_s,
            }
          end
        end

        attribute :image_name do |essence|
          essence.picture.name
        end

        attribute :image_file_name do |essence|
          essence.picture.image_file_name
        end

        attribute :image_mime_type do |essence|
          "image/#{essence.picture.image_file_format}"
        end

        attribute :image_file_size do |essence|
          essence.picture.image_file_size
        end
      end
    end
  end
end
