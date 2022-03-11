struct State {
    private var data: [Row] {
        didSet {
            todosList.elements = data.indices(completed: false)
            todosList.clamp()
            donesList.elements = data.indices(completed: true)
            donesList.clamp()
        }
    }

    init(data: [Row]) {
        self.data = data
        todosList = List(
            name: "TODO",
            current: 0,
            elements: data.indices(completed: false)
        )
        donesList = List(
            name: "DONE",
            current: 0,
            elements: data.indices(completed: true)
        )
    }

    var todosList: List
    var donesList: List

    func task(at index: Int) -> Todo {
        data[index].todo!
    }

    mutating func addTask(_ text: String) {
        if let last = data.last, last.todo == nil {
            data.append(.unrecognized(""))
        }
        data.append(
            .task(.init(completed: false, text: text))
        )
    }

    mutating func markTaskAsDone() {
        let index = todosList.currentTodoIndex!
        data[index].todo?.completed = true
    }

    mutating func markTaskAsTodo() {
        let index = donesList.currentTodoIndex!
        data[index].todo?.completed = false
    }

    func save(to filePath: String) throws {
        let lines: [String] = data.map {
            switch $0 {
            case let .task(task):
                return "- [\(task.completed ? "x" : " ")] \(task.text)"
            case let .unrecognized(text):
                return text
            }
        }
        let contents = lines.joined(separator: "\n")
        try contents.write(toFile: filePath, atomically: true, encoding: .utf8)
    }
}

extension Array where Element == Row {
    func indices(completed: Bool) -> [Int] {
        enumerated()
            .filter { _, row in
                if let todo = row.todo, todo.completed == completed {
                    return true
                }
                return false
            }
            .map { i, _ in i }
    }
}

enum Row {
    case task(Todo)
    case unrecognized(String)

    var todo: Todo? {
        get {
            if case let Row.task(todo) = self {
                return todo
            }
            return nil
        }
        set {
            precondition(self.todo != nil)
            precondition(newValue != nil)
            self = .task(newValue!)
        }
    }
}

struct Todo {
    var completed: Bool
    var text: String
}

struct List {
    let name: String
    private(set) var current: Int?
    fileprivate(set) var elements: [Int]

    var currentTodoIndex: Int? {
        guard !elements.isEmpty else {
            return nil
        }
        guard let current = current else {
            return nil
        }

        return elements[current]
    }

    mutating func clamp() {
        guard !elements.isEmpty else {
            current = nil
            return
        }
        if current != nil {
            current = max(min(current!, elements.count - 1), 0)
        } else {
            current = 0
        }
    }

    mutating func up() {
        guard !elements.isEmpty else {
            current = nil
            return
        }
        if current != nil {
            current! -= 1
            clamp()
        } else {
            current = 0
        }
    }

    mutating func down() {
        guard !elements.isEmpty else {
            current = nil
            return
        }
        if current != nil {
            current! += 1
            clamp()
        } else {
            current = 0
        }
    }
}
