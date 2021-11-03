require 'active_support/inflector'
require "byebug"

class ModelBase 

    def self.find_by_id(id)
        options = QuestionsDBConnections.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                #{self.to_s.tableize}
            WHERE
                id = ?
            SQL
        self.new(options.first)
    end

    # def insert
    #     vars = self.instance_variables.map(&:to_s)
    #     id = vars.shift
    #     params = vars.map { |ele| self.instance_variable_get(ele) }
    #     vars = vars.map { |ele| ele[1..-1] }
    #     table = "#{self.to_s.tableize}" 
    #     QuestionsDBConnections.instance.execute(<<-SQL, *params)
    #     INSERT INTO 
    #         #{"users"}
    #     VALUES
    #         (?, ?)
    #     SQL
    #     self.id = QuestionsDBConnections.instance.last_insert_row_id
    # end

    # def update
    #     QuestionsDBConnections.instance.execute(<<-SQL, *self.instance_variables)
    #     UPDATE 
    #         users
    #     SET
    #         firstname = ?, lastname=?
    #     WHERE
    #         id = ?
    #     SQL
    # end

    # def save
    #     if self.id
    #         self.update
    #     else
    #         self.insert
    #     end
    # end

end