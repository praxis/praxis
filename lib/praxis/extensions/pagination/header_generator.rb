module Praxis
  module Extensions
    module Pagination
      class HeaderGenerator        
        def self.build_cursor_headers(paginator:, last_value:, total_count: nil)
          [:next, :prev, :first, :last].each_with_object({}) do |rel_name, info|
            case rel_name
            when :next
              # If we don't know the total, we'll try to go to the next page
              # but assume we're done if there isn't a last value...
              if last_value
                info[:next] = { by: paginator.by, from: last_value, items: paginator.items }
                info[:next][:total_count] = true if total_count.present?
              end
            when :prev
            # Not possible to go back
            when :first
              info[:first] = { by: paginator.by, items: paginator.items }
              info[:first][:total_count] = true if total_count.present?
            when :last
              # Not possible to scroll to last
            end
          end
        end

        # This is only for plain paging
        def self.build_paging_headers(paginator:, total_count: nil)
          last_page = total_count.nil? ? nil : (total_count / (paginator.items * 1.0)).ceil
          [:next, :prev, :first, :last].each_with_object({}) do |rel_name, info|
            num = case rel_name
                  when :first
                    1
                  when :prev
                    next if paginator.page < 2
                    paginator.page - 1
                  when :next
                    # don't include this link if we know the total and we see there are no more pages
                    next if last_page.present? && (paginator.page >= last_page)
                    # if we don't know the total, we'll specify to the next page even if it ends up being blank
                    paginator.page + 1
                  when :last
                    next if last_page.blank?
                    last_page
                  end
            info[rel_name] = {
              page:         num,
              items:        paginator.items,
              total_count:  total_count.present?
            }
          end
        end

        def self.generate_headers(links:, current_url:, current_query_params:, total_count:)
          mapped = links.map do |(rel, info)|
            # Make sure to encode it our way (with comma-separated args, as it is our own syntax, and not a query string one)
            pagination_param = info.map { |(k, v)| "#{k}=#{v}" }.join(",")
            new_url = current_url + "?" + current_query_params.dup.merge("pagination" => pagination_param).to_query

            LinkHeader::Link.new(new_url, [["rel", rel.to_s]])
          end
          link_header = LinkHeader.new(mapped)

          headers = { "Link" => link_header.to_s }
          headers["Total-Count"] = total_count if total_count
          headers
        end
      end
    end
  end
end
