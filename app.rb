require 'sqlite3'
require 'sinatra'
require 'securerandom'

def generate_sid
    SecureRandom.hex[-4..-1]
end

def generate_pid
    SecureRandom.hex
end

def mask_id unmasked_id
  if !unmasked_id || unmasked_id.length <= 4 then
    return unmasked_id
  else
    return unmasked_id[-4..-1]
  end
end

db = SQLite3::Database.open 'data.db'

db.execute "CREATE TABLE IF NOT EXISTS sessions(sid STRING PRIMARY KEY, p1 INTEGER, p2 INTEGER, p3 INTEGER, p4 INTEGER, p5 INTEGER, p6 INTEGER, p7 INTEGER)"
db.execute "CREATE TABLE IF NOT EXISTS scores(sid STRING PRIMARY KEY, p1 INTEGER, p2 INTEGER, p3 INTEGER, p4 INTEGER, p5 INTEGER, p6 INTEGER, p7 INTEGER, FOREIGN KEY (sid) REFERENCES sessions(sid))"

# TODO: Toggle CORS
before do
    response.headers['Access-Control-Allow-Origin'] = '*'
end


get '/new' do
    sid = generate_sid
    p1 = generate_pid
    db.execute "INSERT INTO sessions (sid,p1) VALUES (?,?)", sid, p1
    logger.info "Created new session (#{sid})"

    # TODO: Join existing session if pid is already in an active one
    # TODO: Track active sessions based on time of creation

    content_type :json
    {"sid": sid, "pid": p1}.to_json
end

get '/join/:sid' do |sid|
    # TODO: Guard against SQL injections
    sessions = db.execute "SELECT * FROM sessions WHERE sid=?", sid
    db.execute "SELECT * FROM sessions WHERE sid=?", sid do |session|
      remaining_spaces = session.count(nil)
      if remaining_spaces > 0 then
        first_nil_index = session.index(nil)
        session[first_nil_index] = generate_pid
        db.execute "UPDATE sessions SET p1=?,p2=?,p3=?,p4=?,p5=?,p6=?,p7=? WHERE sid=?", session[1], session[2], session[3], session[4], session[5], session[6], session[7], session[0]
        logger.info "Modified session (#{sid}) to include new player"

        content_type :json
        return {"sid": session[0],
                "p1": mask_id(session[1]),
                "p2": mask_id(session[2]),
                "p3": mask_id(session[3]),
                "p4": mask_id(session[4]),
                "p5": mask_id(session[5]),
                "p6": mask_id(session[6]),
                "p7": mask_id(session[7]),
        }.to_json
      else
        # TODO: sorry! no room
        logger.info "Player tried to join full session (#{sid})"

        content_type :json
        return {"error": "session #{sid} is full!"}.to_json
      end
      break # safeguard: limit to one row/iteration
    end

    return {"error": "something else"}.to_json
end

put '/advance/:sid' do |sid|
end
