# _plugins/file_tree.rb
module Jekyll
  class FileTreeTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      base = markup.strip
      @base = base.empty? ? nil : base
    end

    def render(context)
      site = context.registers[:site]
      # current page URL from Liquid context
      current_url = context['page'] && context['page']['url']

      pages = if @base
        site.pages.select { |p| p.path.start_with?("#{@base}/") }
      else
        site.pages
      end

      root = { 'children' => {}, 'pages' => [] }
      pages.each do |page|
        rel = @base ? page.path.sub(/^#{Regexp.escape(@base)}\//, '') : page.path
        parts = rel.split('/')
        insert_node(root, parts, page, 0)
      end

      "<ul>\n#{build_items(root, current_url)}</ul>\n"
    end

    private

    def insert_node(node, parts, page, depth)
      name = parts.first
      if parts.size == 1
        if name =~ /^index\./i
          node['page'] = page if depth > 0
        else
          node['pages'] << page
        end
      else
        node['children'][name] ||= { 'page' => nil, 'children' => {}, 'pages' => [] }
        insert_node(node['children'][name], parts[1..], page, depth + 1)
      end
    end

    def build_items(node, current_url, indent = 2)
      out = ''
      prefix = ' ' * indent

      # Directories with index pages
      sorted_dirs = node['children'].sort_by do |name, child|
        page = child['page']
        [
          -(page&.data&.fetch('priority', 0) || 0),
          (page&.data&.fetch('title', name) || name).downcase
        ]
      end

      sorted_dirs.each do |dir, child|
        next unless child['page']
        page = child['page']
        title = page.data['title'] || dir
        url = page.url
        active_attr = (url == current_url) ? ' class="active"' : ''
        out << "#{prefix}<li><a href=\"#{url}\"#{active_attr}>#{title}</a>\n"
        sub = build_items(child, current_url, indent + 2)
        unless sub.empty?
          out << "#{prefix}  <ul>\n#{sub}#{prefix}  </ul>\n"
        end
        out << "#{prefix}</li>\n"
      end

      # Pages in current node
      node['pages']
        .sort_by { |p| [-(p.data['priority'] || 0), (p.data['title'] || File.basename(p.path, '.*')).downcase] }
        .each do |page|
          title = page.data['title'] || File.basename(page.path, '.*')
          url = page.url
          active_attr = (url == current_url) ? ' class="active"' : ''
          out << "#{prefix}<li><a href=\"#{url}\"#{active_attr}>#{title}</a></li>\n"
        end

      out
    end

  end
end

Liquid::Template.register_tag 'file_tree', Jekyll::FileTreeTag
