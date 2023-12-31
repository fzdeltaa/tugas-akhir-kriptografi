get '/all' do
  require_login
  @displayname = User.find(session[:userid]).displayname
  @users = User.where.not(userid: session[:userid])
  @search = true
  erb :index
end

get '/messages/?:userid?' do
  require_login

  subquery = Message.select('MAX(messageid) AS max_id')
                    .group('LEAST(senderid, receiverid), GREATEST(senderid, receiverid)')

  @users = Message.select('messages.*, users.userid, users.displayname, users.username')
                  .joins('INNER JOIN users ON (messages.senderid = users.userid OR messages.receiverid = users.userid)')
                  .where("(messages.senderid = ? OR messages.receiverid = ?) AND messages.messageid IN (#{subquery.to_sql})", session[:userid], session[:userid])
                  .where.not('users.userid = ?', session[:userid])
  @users.each do |user|
    receiver_username = User.find(user.receiverid).username
    user.content = decrypt_aes(user.content, receiver_username)
    user.content = encrypt_reverse(user.content) if user.dobel == 1
  end

  @displayname = User.find(session[:userid]).displayname

  if params[:userid]
    if params[:userid] == session[:userid]
      redirect '/'
    end
    begin
      @receiver = User.find(params[:userid])
      @messages = Message.where('(senderid = ? AND receiverid = ?) OR (senderid = ? AND receiverid = ?)',
                                session[:userid], params[:userid], params[:userid], session[:userid]).order('timestamp ASC')

      @messages.each do |message|
        receiver_id = Message.find(message.messageid).receiverid
        receiver_username = User.find(receiver_id).username
        message.content = decrypt_aes(message.content, receiver_username)

        message.content = encrypt_reverse(message.content) if message.dobel == 1
      end

      @show_right_partial = true
    rescue ActiveRecord::RecordNotFound
      redirect '/'
    end
  end

  erb :index
end

post '/messages/:userid' do
  require_login
  dobel = 1
  dobel = 0 if params['reverse'] == 'benar'

  content = encrypt_reverse(params['content'])

  username = User.find(params['receiverid']).username
  content = encrypt_aes(content, username)
  if params['file']
    time = Time.new
    filename = "#{time.strftime('%s')}#{rand(1..100)}.png"
    image_path = "/img/#{filename}"

    if params['reverse'] == 'benar'
      encrypt_stegano(ChunkyPNG::Image.from_file(params[:file][:tempfile]), "./public#{image_path}")
    else
      File.open("./public#{image_path}", 'wb') do |f|
        f.write(params[:file][:tempfile].read)
      end
    end
  end

  Message.create(senderid: session[:userid], receiverid: params['receiverid'], content: content, image_url: image_path, dobel: dobel)
  params.delete('file')
  redirect "/messages/#{params['receiverid']}"
end
