require "sqlite3"
require "singleton"
require_relative "./modelbase.rb"

class QuestionsDBConnections < SQLite3::Database
    include Singleton 

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end

end

class User < ModelBase

    attr_accessor :firstname, :lastname, :id

    def self.all
        data = QuestionsDBConnections.instance.execute("SELECT * FROM users")
        data.map {|datum| [User.new(datum)]}
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

    def instance_variables
        {firstname: @firstname, lastname: @lastname}
    end

    def insert
        QuestionsDBConnections.instance.execute(<<-SQL, self.firstname, self.lastname)
        INSERT INTO 
        users(firstname, lastname)
        VALUES
        (?, ?)
        SQL
        self.id = QuestionsDBConnections.instance.last_insert_row_id
    end

    def update
        QuestionsDBConnections.instance.execute(<<-SQL, self.firstname, self.lastname, self.id)
        UPDATE 
            users
        SET
            firstname = ?, lastname=?
        WHERE
            id = ?
        SQL
    end

    def save
        if self.id
            self.update
        else
            self.insert
        end
    end

    def avg_karma
        avg = QuestionsDBConnections.instance.execute(<<-SQL, self.id)
            SELECT
                CAST(COUNT(question_likes.user_id) AS FLOAT) / COUNT(questions.id)
            FROM 
                questions
                JOIN question_likes ON questions.id = question_likes.question_id
            WHERE
                questions.author_id = ? 
            SQL
        avg.first['CAST(COUNT(question_likes.user_id) AS FLOAT) / COUNT(questions.id)'] 
    end

    def liked_questions
        QuestionLike.liked_questions_for_user_id(self.id)
    end

    def authored_questions
        Question.find_by_author_id(self.id)
    end

    def authored_replies
        Reply.find_by_user_id(self.id)
    end

    def followed_questions 
        QuestionFollow.followed_questions_for_user_id(self.id)
    end
end

class Question

    def self.all
        data = QuestionsDBConnections.instance.execute("SELECT * FROM questions")
        data.map {|datum| [Question.new(datum)]}
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

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def self.most_liked(n)
        QuestionLike.most_liked_questions(n)
    end

    attr_accessor :title, :body, :author_id, :id

    def initialize(options)
        @id, @title, @body, @author_id = options['id'], options['title'], options['body'], options['author_id']
    end

    def insert
        QuestionsDBConnections.instance.execute(<<-SQL, self.title, self.body, self.author_id)
        INSERT INTO 
        questions(title, body, author_id)
        VALUES
        (?, ?, ?)
        SQL
        self.id = QuestionsDBConnections.instance.last_insert_row_id
    end

    def update
        QuestionsDBConnections.instance.execute(<<-SQL, self.title, self.body, self.author_id, self.id)
        UPDATE 
            questions
        SET
            title = ?, body = ?, author_id = ?
        WHERE
            id = ?
        SQL
    end

    def save
        if self.id
            self.update
        else
            self.insert
        end
    end

    def likers 
        QuestionLike.likers_for_question_id(self.id)
    end

    def num_likes 
        QuestionLike.num_likes_for_question_id(self.id)
    end

    def author 
        User.find_by_id(self.author_id)
    end

    def replies
        Reply.find_by_question_id(self.id)
    end

    def followers 
        QuestionFollow.followers_for_question_id(self.id)
    end

end

class Reply

    attr_accessor :id, :original_q_id, :reply_id, :replier_id, :body

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
    
    def update
        QuestionsDBConnections.instance.execute(<<-SQL, self.original_q_id, self.reply_id, self.replier_id, self.body, self.id)
        UPDATE 
            replies
        SET
            original_q_id = ?, reply_id = ?, replier_id = ?, body = ?
        WHERE
            id = ?
        SQL
    end

    def save
        if self.id
            self.update
        else
            self.insert
        end
    end

    def author
        User.find_by_id(self.replier_id)
    end

    def question
        Question.find_by_id(self.original_q_id)
    end

    def parent_reply
        Reply.find_by_id(self.reply_id)
    end

    def child_replies
        children = QuestionsDBConnections.instance.execute(<<-SQL, self.id)
        SELECT
            *
        FROM 
            replies
        WHERE
            reply_id = ?
        SQL
        children.map {|r| Reply.new(r)}
    end
end

class QuestionFollow
    def self.followers_for_question_id(question_id)
        users = QuestionsDBConnections.instance.execute(<<-SQL, question_id)
            SELECT
                users.id, users.firstname, users.lastname
            FROM
                question_follows
                JOIN
                    users ON question_follows.user_id = users.id
            WHERE
                question_id = ?
        SQL
        users.map { |u| User.new(u) }
    end

    def self.followed_questions_for_user_id(user_id)
        questions = QuestionsDBConnections.instance.execute(<<-SQL, user_id)
        SELECT
            questions.id, questions.title, questions.body, questions.author_id
        FROM
            question_follows
            JOIN
                questions ON question_follows.question_id = questions.id
        WHERE
            user_id = ?
        SQL
        questions.map { |q| Question.new(q) }
    end

    def self.most_followed_questions(n)
        questions = QuestionsDBConnections.instance.execute(<<-SQL, n)
        SELECT
            questions.id, questions.title, questions.body, questions.author_id
        FROM
            question_follows 
            JOIN questions ON question_follows.question_id = questions.id
        GROUP BY
            question_id
        ORDER BY
            COUNT(user_id) DESC
        LIMIT ?
        SQL
        questions.map {|q| Question.new(q)}
    end
end


class QuestionLike
    def self.likers_for_question_id(question_id)
        users = QuestionsDBConnections.instance.execute(<<-SQL, question_id)
            SELECT
                users.id, users.firstname, users.lastname
            FROM
                question_likes
                JOIN
                    users ON question_likes.user_id = users.id
            WHERE
                question_id = ?
        SQL
        users.map { |u| User.new(u) }
    end

    def self.num_likes_for_question_id(question_id)
        n = QuestionsDBConnections.instance.execute(<<-SQL, question_id)
            SELECT
                COUNT(users.id)
            FROM
                question_likes
                JOIN
                    users ON question_likes.user_id = users.id
            WHERE
                question_id = ?
            SQL
        n.first["COUNT(users.id)"]
    end

    def self.liked_questions_for_user_id(user_id)
        questions = QuestionsDBConnections.instance.execute(<<-SQL, user_id)
        SELECT
            questions.id, questions.title, questions.body, questions.author_id
        FROM
            question_likes
            JOIN
                questions ON question_likes.question_id = questions.id
        WHERE
            user_id = ?
    SQL
    questions.map { |q| Question.new(q) }
    end

    def self.most_liked_questions(n)
        questions = QuestionsDBConnections.instance.execute(<<-SQL, n)
        SELECT
            questions.id, questions.title, questions.body, questions.author_id
        FROM
            question_likes
            JOIN questions ON question_likes.question_id = questions.id
        GROUP BY
            question_id
        ORDER BY
            COUNT(user_id) DESC
        LIMIT ?
        SQL
        questions.map {|q| Question.new(q)}
    end
end

# user = User.new("id" => nil, "firstname" => "Zack", "lastname" => "Garnett")
# user.insert
# p User.all
