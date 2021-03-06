require 'mini_magick'
require 'fileutils'
require 'mimemagic'

class Imageboard
  # Board index page.
  # NOTE: This catches stuff in public too that doesn't exist.
  get '/:board' do
    return redirect "/#{params[:board]}/"
  end

  get '/:board/' do
    board = Board.find_by(route: params[:board])
    if board.nil?
      flash[:error] = "The board you selected doesn't exist!"
      return redirect '/'
    else
      locals = {
        title: "/#{board.route}/ - #{board.name}",
        type: 'catalog',
        board: board,
        boards: Board.all,
        yarns: board.yarns.reverse
      }

      slim :board, locals: locals
    end
  end

  post '/:board/' do
    board = Board.find_by(route: params[:board])

    if board.nil?
      flash[:error] = "The board you selected doesn't exist!"
      return redirect '/'
    end

    return redirect '/banned' if Ban.banned? request.ip

    if !params.key?('file') || !params[:file].is_a?(Hash)
      flash[:error] = "You can't start a thread with no file!"
      return redirect "/#{board.route}"
    end

    if params.key?('body') && (params[:body].length > $CONFIG[:character_limit])
      flash[:error] = "Your text post exceeds #{$CONFIG[:character_limit]} characters."
      return redirect "/#{board.route}"
    end

    file = params[:file][:tempfile]
    filetype = MimeMagic.by_path(file.path)

    if filetype.subtype !~ /jpeg|gif|png/
      flash[:error] = 'The file you provided is of invalid type.'
      return redirect "/#{board.route}"
    end

    if file.size > $CONFIG[:max_filesize]
      flash[:error] = 'The file you provided is too large.'
      return redirect "/#{board.route}"
    end

    begin
      image = MiniMagick::Image.read(file)
    rescue MiniMagick::Invalid
      flash[:error] = 'The image you provided is invalid.'
      return redirect "/#{board.route}"
    end

    properties = {}

    unless image.valid?
      flash[:error] = 'The image you provided is invalid.'
      return redirect "/#{board.route}"
    end

    # Generate a UUID
    properties[:uuid] = Image.uuid

    # Establish the image's common properties.
    properties.merge!(width: image.width,
                      height: image.height,
                      type: image.type.downcase)

    # Save the original.
    unless Dir.exist? "#{$ROOT}/public/images/#{board.route}"
      FileUtils.mkpath "#{$ROOT}/public/images/#{board.route}"
    end

    filename = "#{properties[:uuid]}.#{properties[:type]}"
    image.write "#{$ROOT}/public/images/#{board.route}/#{filename}"

    # Save the thumbnail.
    unless Dir.exist? "#{$ROOT}/public/thumbs/#{board.route}"
      FileUtils.mkpath "#{$ROOT}/public/thumbs/#{board.route}"
    end

    image.combine_options do |c|
      c.resize '250x250'
    end.format('jpg').write "#{$ROOT}/public/thumbs/#{board.route}/#{filename}"

    image.destroy!

    post = Post.create(name: params[:name],
                       time: DateTime.now,
                       body: params[:body].strip,
                       spoiler: params[:spoiler] == 'on',
                       ip: request.ip)

    yarn = Yarn.create(number: post.number,
                       board: board.route,
                       updated: DateTime.now,
                       subject: params[:subject],
                       locked: false)

    post.update(yarn: post.number)

    imagefile = Image.create(post: post.number,
                             extension: properties[:type],
                             name: filename,
                             width: properties[:width],
                             height: properties[:height])

    return redirect "/#{board.route}/thread/#{yarn.number}"
  end
end
