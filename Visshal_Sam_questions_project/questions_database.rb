require "sqlite3"
require "singleton"

class QuestionsDBConnections < SQLite3::Database
    include Singleton 

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end

end

class User

    attr_accessor :firstname, :lastname, :id

    def self.all
        data = QuestionsDBConnections.instance.execute("SELECT * FROM users")
        data.map {|datum| [User.new(datum)]}
    end

    def self.find_by_id(id)
        options = QuestionsDBConnections.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?
            SQL
        User.new(options.first)
    end

     def self.find_by_name(f_name, l_name)
        options = QuestionsDBConnections.instance.execute(<<-SQL, f_name, l_name)
            SELECT
                *
            FROM
                users
            WHERE
                firstname = ? AND lastname = ?
            SQL
            # implement for multiple same names
        User.new(options.first)
    end


    def initialize(options)
        @id, @firstname, @lastname = options['id'], options['firstname'], options['lastname']
    end

    def insert
        raise "user already exists" if self.id
        QuestionsDBConnections.instance.execute(<<-SQL, self.firstname, self.lastname)
        INSERT INTO 
        users(firstname, lastname)
        VALUES
        (?, ?)
        SQL
        self.id = QuestionsDBConnections.instance.last_insert_row_id
    end

    def authored_questions
        Question.find_by_author_id(self.id)
    end

    def authored_replies
        Reply.find_by_user_id(self.id)
    end
end

class Question

    def self.all
        data = QuestionsDBConnections.instance.execute("SELECT * FROM questions")
        data.map {|datum| [Question.new(datum)]}
    end

    def self.find_by_id(id)
        options = QuestionsDBConnections.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
            SQL
        Question.new(options.first)
    end

    def self.find_by_author_id(author_id)
        question = QuestionsDBConnections.instance.execute(<<-SQL, author_id)
        SELECT
            *
        FROM 
            questions
        WHERE
            author_id = ?
        SQL
        question.map {|q| Question.new(q)}
    end
    attr_accessor :title, :body, :author_id, :id

    def initialize(options)
        @id, @title, @body, @author_id = options['id'], options['title'], options['body'], options['author_id']
    end

    def insert
        raise "that row already exists" if self.id
        QuestionsDBConnections.instance.execute(<<-SQL, self.title, self.body, self.author_id)
        INSERT INTO 
        questions(title, body, author_id)
        VALUES
        (?, ?, ?)
        SQL
        self.id = QuestionsDBConnections.instance.last_insert_row_id
    end

end

class Reply

    attr_accessor :original_q_id, :reply_id, :replier_id, :body, :id

    def self.find_by_id(id)
        options = QuestionsDBConnections.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies
            WHERE
                id = ?
            SQL
        Reply.new(options.first)
    end

    def self.all
        data = QuestionsDBConnections.instance.execute("SELECT * FROM replies")
        data.map {|datum| [Reply.new(datum)]}
    end

    def self.find_by_user_id(user_id)
        reply = QuestionsDBConnections.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM 
            replies
        WHERE
            replier_id = ?
        SQL
        reply.map {|r| Reply.new(r)}
    end

    def self.find_by_question_id(question_id)
        reply = QuestionsDBConnections.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM 
            replies
        WHERE
            original_q_id = ?
        SQL
        #implement order by for threads
        reply.map {|r| Reply.new(r)}
    end

    def initialize(options)
        @id = options['id']
        @original_q_id = options['original_q_id']
        @reply_id = options['reply_id']
        @replier_id =options['replier_id']
        @body = options['body']
    end

    def insert
        raise "reply already exists" if self.id
        QuestionsDBConnections.instance.execute(<<-SQL, self.original_q_id, self.reply_id, self.replier_id, self.body)
        INSERT INTO 
        replies(original_q_id, reply_id, replier_id, body)
        VALUES
        (?, ?, ?, ?)
        SQL
        self.id = QuestionsDBConnections.instance.last_insert_row_id
    end
end



